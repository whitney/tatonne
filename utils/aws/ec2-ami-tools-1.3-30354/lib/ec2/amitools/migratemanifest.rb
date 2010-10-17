# Copyright 2008 Amazon.com, Inc. or its affiliates.  All Rights
# Reserved.  Licensed under the Amazon Software License (the
# "License").  You may not use this file except in compliance with the
# License. A copy of the License is located at
# http://aws.amazon.com/asl or in the "license" file accompanying this
# file.  This file is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
# the License for the specific language governing permissions and
# limitations under the License.

require 'ec2/amitools/migratemanifestparameters'
require 'ec2/amitools/manifest_wrapper'
require 'fileutils'
require 'csv'
require 'net/http'
require 'ec2/amitools/tool_base'

MIGRATE_MANIFEST_NAME = "ec2-migrate-manifest"

MIGRATE_MANIFEST_MANUAL =<<TEXT
#{MIGRATE_MANIFEST_NAME} is a command line tool to assist with migrating AMIs to new regions.

#{MIGRATE_MANIFEST_NAME} will:
- automatically replace kernels and ramdisks with replacements suitable for a
  particular target region
- optionally replace kernels and ramdisks with user-specified replacements

TEXT

class BadManifestError < RuntimeError
  def initialize(manifest, msg)
    super("Bad manifest '#{manifest}': #{msg}")
  end
end

class ManifestMigrator < AMITool
  include EC2::Platform::Current::Constants
  
  def get_manifest(manifest_path, user_cert_path)
    unless File::exists?(manifest_path)
      raise BadManifestError.new(manifest_path, "File not found.")
    end
    begin
      manifest = ManifestWrapper.new(File.open(manifest_path).read())
    rescue ManifestWrapper::InvalidManifest => e
      raise BadManifestError.new(manifest_path, e.message)
    end
    unless manifest.authenticate(File.open(user_cert_path))
      raise BadManifestError.new(manifest_path, "Manifest fails authentication.")
    end
    manifest
  end

  #----------------------------------------------------------------------------#

  def make_s3_connection(s3_url, user, pass, bucket)
    s3_uri = URI.parse(s3_url)
    s3_url = uri2string(s3_uri)
    v2_bucket = EC2::Common::S3Support::bucket_name_s3_v2_safe?(bucket)
    EC2::Common::S3Support.new(s3_url, user, pass, (v2_bucket ? nil : :path))
  end

  #----------------------------------------------------------------------------#

  def find_mapping(mapping_csv, object, region)
    mapping = CSV::parse(mapping_csv)
    regions = mapping.shift()
    unless regions.include?(region)
      raise EC2FatalError.new(1, "Region '#{region}' not found in mapping file.")
    end
    right_row = mapping.select do |row|
      row.include?(object)
    end
    if right_row.size < 1
      raise EC2FatalError.new(1, "'#{object}' not found in mapping file.")
    end
    if right_row.size > 1
      raise EC2FatalError.new(1, "'#{object}' duplicated in mapping file.")
    end
    region_index = regions.index(region)
    right_row[0][region_index]
  end

  #----------------------------------------------------------------------------#

  def get_mapping_csv_internal(mapping_url, mapping_file)
    if mapping_url
      begin
        response = Net::HTTP::get_response(URI.parse(mapping_url))
        if response.is_a? Net::HTTPOK
          return response.body
        else
          $stderr.puts "Unable to reach '#{mapping_url}': #{response.code} #{response.message}"
          if @debug
            $stderr.puts "Response body:"
            $stderr.puts e.body
          end
        end
      rescue => e
        $stderr.puts "Unable to reach '#{mapping_url}': #{e.message}"
        $stderr.puts e.backtrace if @debug
      end
      $stderr.puts "Falling back to local file..."
    end
    
    if mapping_file
      return File.open(mapping_file) { |file| file.read() }
    end
    raise EC2FatalError.new(5, "Can't find mapping information.")
  end

  #----------------------------------------------------------------------------#

  def get_mapping_csv(use_mapping, mapping_url, mapping_file)
    return nil unless use_mapping
    if mapping_url or mapping_file
      get_mapping_csv_internal(mapping_url, mapping_file)
    else
      get_mapping_csv_internal(Bundling::EC2_MAPPING_URL, Bundling::EC2_MAPPING_FILE)
    end
  end

  #----------------------------------------------------------------------------#

  def map_identifiers(manifest, mapping_csv, region, kernel_id=nil, ramdisk_id=nil)
    unless mapping_csv.nil?
      if region.nil?
        raise EC2FatalError.new(1, "No region provided, cannot map automatically.")
      end
      if manifest.kernel_id
        kernel_id ||= find_mapping(mapping_csv, manifest.kernel_id, region)
      end
      if manifest.ramdisk_id
        ramdisk_id ||= find_mapping(mapping_csv, manifest.ramdisk_id, region)
      end
    end
    [kernel_id, ramdisk_id]
  end

  #----------------------------------------------------------------------------#

  def backup_manifest(manifest_path, quiet=false)
    backup_manifest = "#{manifest_path}.bak"
    if File::exists?(backup_manifest)
      raise EC2FatalError.new(2, "Backup file '#{backup_manifest}' already exists. Please delete or rename it and try again.")
    end
    $stdout.puts("Backing up manifest...") unless quiet
    $stdout.puts("Backup manifest at #{backup_manifest}") if @debug
    FileUtils::copy(manifest_path, backup_manifest)
  end

  #----------------------------------------------------------------------------#

  def build_migrated_manifest(manifest, user_pk_path, kernel_id=nil, ramdisk_id=nil)
    new_manifest = ManifestV20071010.new()
    manifest_params = {
      :name => manifest.name,
      :user => manifest.user,
      :image_type => manifest.image_type,
      :arch => manifest.arch,
      :reserved => nil,
      :parts => manifest.parts.map { |part| [part.filename, part.digest] },
      :size => manifest.size,
      :bundled_size => manifest.bundled_size,
      :user_encrypted_key => manifest.user_encrypted_key,
      :ec2_encrypted_key => manifest.ec2_encrypted_key,
      :cipher_algorithm => manifest.cipher_algorithm,
      :user_encrypted_iv => manifest.user_encrypted_iv,
      :ec2_encrypted_iv => manifest.ec2_encrypted_iv,
      :digest => manifest.digest,
      :digest_algorithm => manifest.digest_algorithm,
      :privkey_filename => user_pk_path,
      :kernel_id => kernel_id,
      :ramdisk_id => ramdisk_id,
      :product_codes => manifest.product_codes,
      :ancestor_ami_ids => manifest.ancestor_ami_ids,
      :block_device_mapping => manifest.block_device_mapping,
      :bundler_name => manifest.bundler_name,
      :bundler_version => manifest.bundler_version,
      :bundler_release => manifest.bundler_release,
      :kernel_name => manifest.kernel_name,
    }
    new_manifest.init(manifest_params)
    new_manifest
  end

  #----------------------------------------------------------------------------#

  def check_and_warn(manifest, kernel_id, ramdisk_id)
    if (manifest.kernel_id and kernel_id.nil?) or (manifest.ramdisk_id and ramdisk_id.nil?)
      message = ["This operation will remove the kernel and/or ramdisk associated with",
                 "the AMI. This may cause the AMI to fail to launch unless you specify",
                 "an appropriate kernel and ramdisk at launch time.",
                ].join("\n")
      unless warn_confirm(message)
        raise EC2StopExecution.new()
      end
    end
  end

  #----------------------------------------------------------------------------#

  def migrate_manifest(manifest_path,
                       user_pk_path,
                       user_cert_path,
                       kernel_id=nil,
                       ramdisk_id=nil,
                       region=nil,
                       use_mapping=true,
                       mapping_url=nil,
                       mapping_file=nil,
                       quiet=false)
    manifest = get_manifest(manifest_path, user_cert_path)
    backup_manifest(manifest_path, quiet)
    mapping_csv = get_mapping_csv(use_mapping, mapping_url, mapping_file)
    kernel_id, ramdisk_id = map_identifiers(manifest, mapping_csv, region, kernel_id, ramdisk_id)
    check_and_warn(manifest, kernel_id, ramdisk_id)
    new_manifest = build_migrated_manifest(manifest, user_pk_path, kernel_id, ramdisk_id)
    File.open(manifest_path, 'w') { |f| f.write(new_manifest.to_s) }
    $stdout.puts("Successfully migrated #{manifest_path}") unless quiet
    $stdout.puts("It is now suitable for use in #{region}.") unless quiet
  end

  #------------------------------------------------------------------------------#
  # Overrides
  #------------------------------------------------------------------------------#

  def get_manual()
    MIGRATE_MANIFEST_MANUAL
  end

  def get_name()
    MIGRATE_MANIFEST_NAME
  end

  def main(p)
    migrate_manifest(p.manifest_path,
                     p.user_pk_path,
                     p.user_cert_path,
                     p.kernel_id,
                     p.ramdisk_id,
                     p.region,
                     p.use_mapping,
                     p.mapping_url,
                     p.mapping_file)
  end

end

#------------------------------------------------------------------------------#
# Script entry point. Execute only if this file is being executed.

if __FILE__ == $0
  ManifestMigrator.new().run(MigrateManifestParameters)
end
