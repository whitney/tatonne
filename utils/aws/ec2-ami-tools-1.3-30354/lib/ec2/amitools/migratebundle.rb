# Copyright 2008 Amazon.com, Inc. or its affiliates.  All Rights
# Reserved.  Licensed under the Amazon Software License (the
# "License").  You may not use this file except in compliance with the
# License. A copy of the License is located at
# http://aws.amazon.com/asl or in the "license" file accompanying this
# file.  This file is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
# the License for the specific language governing permissions and
# limitations under the License.

require 'ec2/common/s3support'
require 'ec2/amitools/migratebundleparameters'
require 'ec2/amitools/migratemanifest'
require 'ec2/amitools/downloadbundle'
require 'ec2/amitools/uploadbundle'
require 'fileutils'
require 'ec2/amitools/tool_base'

MIGRATE_BUNDLE_NAME = 'ec2-migrate-bundle'

#------------------------------------------------------------------------------#

MIGRATE_BUNDLE_MANUAL =<<TEXT
#{MIGRATE_BUNDLE_NAME} is a command line tool to assist with migrating AMIs to new regions.

#{MIGRATE_BUNDLE_NAME} will:
- download the manifest of the specified AMI
- attempt to automatically find replacement kernels and ramdisks
- optionally replace kernels and ramdisks with user-specified replacements
- copy AMI into new bucket
- upload new migrated manifest into new bucket

This tool will not register the AMI in the new region.

TEXT

class BundleMigrator < AMITool
  
  # If we return true, we have a v2-compliant name.
  # If we return false, we wish to use a bad name.
  # Otherwise we quietly wander off to die in peace.
  def check_bucket_name(bucket, interactive)
    if EC2::Common::S3Support::bucket_name_s3_v2_safe?(bucket)
      return true
    end
    if interactive
      begin
        $stdout.puts "The specified bucket is not S3 v2 safe (see S3 documentation for details):"
        $stdout.puts bucket
        $stdout.print "Are you sure you want to continue? [y/N]: "
        $stdout.flush
        Timeout::timeout(PROMPT_TIMEOUT) do
          instr = gets
          if instr[0..0] =~ /[Yy]/
            return false
          end
          raise EC2FatalError.new(2, nil)
        end
      rescue Timeout::Error
        raise PromptTimeout.new("bucket name confirmation")
      end
    else
      # If we're in batch mode, assume the customer knows what he wants.
      return false
    end
  end

  def with_temp_dir(manifest_name)
    # Set up temporary dir
    tempdir = File::join(Dir::tmpdir, "ami-migration-#{manifest_name}")
    if File::exists?(tempdir)
      raise EC2FatalError.new(2, "Temporary directory '#{tempdir}' already exists. Please delete or rename it and try again.")
    end
    Dir::mkdir(tempdir)

    # Let the caller use it
    begin
      result = yield tempdir
    rescue Exception => e
      # Nuke it
      FileUtils::rm_rf(tempdir)
      raise e
    end
    # Nuke it
    FileUtils::rm_rf(tempdir)
    result
  end

  def uri2string(uri)
    s = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
    # Remove the trailing '/'.
    return (s[-1..-1] == "/" ? s[0..-2] : s)
  end

  def make_s3_connection(s3_url, user, pass, bucket)
    s3_uri = URI.parse(s3_url)
    s3_url = uri2string(s3_uri)
    v2_bucket = EC2::Common::S3Support::bucket_name_s3_v2_safe?(bucket)
    EC2::Common::S3Support.new(s3_url, user, pass, (v2_bucket ? nil : :path))
  end

  def download_manifest(s3_conn, bucket, manifest_name, manifest_path, user_pk_path, retry_stuff)
    BundleDownloader.new().download_manifest(s3_conn,
                                             bucket,
                                             manifest_name,
                                             manifest_path,
                                             user_pk_path,
                                             retry_stuff)
  end

  def get_part_filenames(manifest_path, user_cert_path)
    manifest = ManifestMigrator.new().get_manifest(manifest_path, user_cert_path)
    manifest.parts.collect { |part| part.filename }.sort
  end

  def copy_part(s3_conn, bucket, dest_bucket, part, acl, retry_copy)
    source = "/#{bucket}/#{part}"
    retry_s3(retry_copy) do
      begin
        s3_conn.copy(dest_bucket, part, source, {"x-amz-acl"=>acl})
        return
      rescue => e
        raise TryFailed.new("Failed to copy \"#{part}\": #{e.message}")
      end
    end
  end

  def create_bucket(dest_s3_conn, dest_bucket, location, retry_stuff)
    uploader = BundleUploader.new()
    dest_bucket_location = uploader.get_bucket_location(dest_s3_conn, dest_bucket)
    uploader.create_bucket(dest_s3_conn, dest_bucket, dest_bucket_location, location, retry_stuff)
  end

  def upload_manifest(s3_conn, manifest_name, manifest_path, bucket, tempdir, acl, retry_stuff)
    BundleUploader.new().upload(s3_conn, bucket, manifest_name, manifest_path, acl, retry_stuff)
  end

  def migrate_bundle(s3_url,
                     bucket,
                     dest_bucket,
                     manifest_name,
                     user_pk_path,
                     user_cert_path,
                     user,
                     pass,
                     location,
                     kernel_id=nil,
                     ramdisk_id=nil,
                     acl='aws-exec-read',
                     retry_stuff=nil,
                     use_mapping=true,
                     mapping_url=nil,
                     mapping_file=nil,
                     region=nil)
    
    src_s3_conn = make_s3_connection(s3_url, user, pass, bucket)
    dest_s3_conn = make_s3_connection(s3_url, user, pass, dest_bucket)
    
    # Locate destination bucket and create it if necessary.
    bu = BundleUploader.new()
    bucket_location = bu.get_bucket_location(dest_s3_conn, dest_bucket)
    bu.create_bucket(dest_s3_conn, dest_bucket, bucket_location, location, retry_stuff)
    
    # Region/location hack:
    if region.nil?
      location ||= bucket_location
      region = "us-east-1"
      region = "eu-west-1" if location == "EU"
      puts "Region not provided, guessing from S3 location: #{region}"
    end
    
    with_temp_dir(manifest_name) do |tempdir|
      manifest_path = File::join(tempdir, manifest_name)
      download_manifest(src_s3_conn, bucket, manifest_name, manifest_path, user_pk_path, retry_stuff)
      
      ManifestMigrator.new().migrate_manifest(manifest_path,
                                              user_pk_path,
                                              user_cert_path,
                                              kernel_id,
                                              ramdisk_id,
                                              region,
                                              use_mapping,
                                              mapping_url,
                                              mapping_file,
                                              true)
      
      create_bucket(dest_s3_conn, dest_bucket, location, retry_stuff)
      get_part_filenames(manifest_path, user_cert_path).each do |part|
        $stdout.puts("Copying '#{part}'...")
        copy_part(dest_s3_conn, bucket, dest_bucket, part, acl, retry_stuff)
      end
      upload_manifest(dest_s3_conn, manifest_name, manifest_path, dest_bucket, tempdir, acl, retry_stuff)
    end
  end

  #------------------------------------------------------------------------------#
  # Overrides
  #------------------------------------------------------------------------------#

  def get_manual()
    MIGRATE_BUNDLE_MANUAL
  end

  def get_name()
    MIGRATE_BUNDLE_NAME
  end

  def main(p)
    check_bucket_name(p.dest_bucket, p.interactive?)
    
    migrate_bundle(p.s3_url,
                   p.bucket,
                   p.dest_bucket,
                   p.manifest_name,
                   p.user_pk_path,
                   p.user_cert_path,
                   p.user,
                   p.pass,
                   p.location,
                   p.kernel_id,
                   p.ramdisk_id,
                   p.acl,
                   p.retry,
                   p.use_mapping,
                   p.mapping_url,
                   p.mapping_file,
                   p.region)
    
    $stdout.puts("\nYour new bundle is in S3 at the following location:")
    $stdout.puts("#{p.dest_bucket}/#{p.manifest_name}")
    $stdout.puts("Please register it using your favorite EC2 client.")
  end

end

#------------------------------------------------------------------------------#
# Script entry point. Execute only if this file is being executed.
if __FILE__ == $0
  BundleMigrator.new().run(MigrateBundleParameters)
end
