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
require 'ec2/amitools/uploadbundleparameters'
require 'uri'
require 'ec2/amitools/instance-data'
require 'ec2/amitools/manifestv20071010'
require 'rexml/document'
require 'digest/md5'
require 'base64'
require 'ec2/amitools/tool_base'

#------------------------------------------------------------------------------#

UPLOAD_BUNDLE_NAME = 'ec2-upload-bundle'

UPLOAD_BUNDLE_MANUAL =<<TEXT
#{UPLOAD_BUNDLE_NAME} is a command line tool to upload a bundled Amazon Image to S3 storage 
for use by EC2. An Amazon Image may be one of the following:
- Amazon Machine Image (AMI)
- Amazon Kernel Image (AKI)
- Amazon Ramdisk Image (ARI)

#{UPLOAD_BUNDLE_NAME} will:
- create an S3 bucket to store the bundled AMI in if it does not already exist
- upload the AMI manifest and parts files to S3, granting specified privileges 
- on them (defaults to EC2 read privileges)

To manually retry an upload that failed, #{UPLOAD_BUNDLE_NAME} can optionally:
- skip uploading the manifest
- only upload bundled AMI parts from a specified part onwards
TEXT

#------------------------------------------------------------------------------#

class BucketLocationError < AMIToolExceptions::EC2FatalError
  def initialize(bucket)
    super(10, "Bucket \"#{bucket}\" location does not match specified location.")
  end
end

#----------------------------------------------------------------------------#

# Upload the specified file.

class BundleUploader < AMITool

  def upload(s3_conn, bucket, file, path, acl, retry_upload)
    retry_s3(retry_upload) do
      begin
        md5 = get_md5(path)
        s3_conn.put(bucket, file, path, {"x-amz-acl"=>acl, "content-md5"=>md5})
        return
      rescue EC2::Common::HTTP::Error::PathInvalid => e
        raise FileNotFound(path)
      rescue => e
        raise TryFailed.new("Failed to upload \"#{path}\": #{e.message}")
      end
    end
  end

  #----------------------------------------------------------------------------#

  def get_md5(file)
    Base64::encode64(Digest::MD5::digest(File.open(file) { |f| f.read })).strip
  end

  #----------------------------------------------------------------------------#

  def get_availability_zone()
    instance_data = EC2::InstanceData.new
    instance_data.availability_zone
  end

  #----------------------------------------------------------------------------#

  # Return a list of bundle part filename and part number tuples from the manifest.
  def get_part_info(manifest)
    parts = manifest.ami_part_info_list.map do |part|
      [part['filename'], part['index']]
    end
    parts.sort
  end

  #------------------------------------------------------------------------------#

  def uri2string(uri)
    s = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
    # Remove the trailing '/'.
    return (s[-1..-1] == "/" ? s[0..-2] : s)
  end

  #------------------------------------------------------------------------------#

  # Get the bucket's location.
  def get_bucket_location(s3_conn, bucket)
    begin
      response = s3_conn.get_bucket_location(bucket)
    rescue EC2::Common::HTTP::Error::Retrieve => e
      if e.code == 404
        # We have a "Not found" S3 response, which probably means the bucket doesn't exist.
        return nil
      end
      raise e
    end
    $stdout.puts "check_bucket_location response: #{response.body}" if @debug and response.text?
    docroot = REXML::Document.new(response.body).root
    bucket_location = REXML::XPath.first(docroot, '/LocationConstraint').text
    bucket_location ||= :unconstrained
  end

  #------------------------------------------------------------------------------#

  # Check if the bucket exists and is in an appropriate location.
  def check_bucket_location(bucket, bucket_location, location)
    if bucket_location.nil?
      # The bucket does not exist. Safe, but we need to create it.
      return false
    end
    if location.nil?
      # The bucket exists and we don't care where it is.
      return true
    end
    if location != bucket_location
      # The bucket isn't where we want it. This is a problem.
      raise BucketLocationError.new(bucket)
    end
    # The bucket exists and is in the right place.
    return true
  end

  #------------------------------------------------------------------------------#

  # Create the specified bucket if it does not exist.
  def create_bucket(s3_conn, bucket, bucket_location, location, retry_create)
    begin
      if check_bucket_location(bucket, bucket_location, location)
        return true
      end
      $stdout.puts "Creating bucket..."
      options = {'Content-Length' => '0'}
      
      retry_s3(retry_create) do
        error = "Could not create or access bucket #{bucket}"
        begin
          rsp = s3_conn.create_bucket(bucket, location == :unconstrained ? nil : location, options)
          return true if rsp.success?
          raise "HTTP PUT returned #{rsp.code}."
        rescue EC2::Common::HTTP::Error::Retrieve => e
          error += ": server response #{e.message} #{e.code}"
        rescue RuntimeError => e
          error += ": error message #{e.message}"
        end
      end
    end
  end

  #------------------------------------------------------------------------------#

  # If we return true, we have a v2-compliant name.
  # If we return false, we wish to use a bad name.
  # Otherwise we quietly wander off to die in peace.
  def check_bucket_name(bucket)
    if EC2::Common::S3Support::bucket_name_s3_v2_safe?(bucket)
      return true
    end
    message = "The specified bucket is not S3 v2 safe (see S3 documentation for details):\n#{bucket}"
    if warn_confirm(message)
      # Assume the customer knows what he's doing.
      return false
    else
      # We've been asked to stop, so quietly wander off to die in peace.
      raise EC2StopExecution.new()
    end
  end

  #------------------------------------------------------------------------------#

  # Horrible hack. :-(
  # This is very much a best effort attempt. If in doubt, we don't warn.
  def cross_region?(location, bucket_location)
    # If the bucket exists, its S3 location is canonical.
    s3_region = bucket_location
    # Otherwise, get the location specified
    s3_region ||= location
    # Here, nil means the bucket does not exist and no location was specified.
    # Thus, the new bucket will be in the unconstrained location:
    s3_region ||= :unconstrained
    
    az = get_availability_zone()
    if az.nil?
      # If we can't get the availability zone, assume we're fine since there's
      # nothing more we can do.
      return false
    end
    # This check assumes the first part of the availability zone name matches the
    # appropriate S3 location name. Special case 'us-...' and no location.
    match = /^([^-]*)-/.match(az)
    if match.nil?
      # No idea where we are. Assume happiness.
      return false
    end
    # Case doesn't matter here.
    az_region = match[1].downcase
    # Special case for S3 empty location:
    if s3_region == :unconstrained
      return az_region != "us"
    end
    # We should only have text regions now, so this is safe.
    return az_region != s3_region.downcase
  end

  #------------------------------------------------------------------------------#

  def warn_about_migrating()
    message = ["You are bundling in one region, but uploading to another. If the kernel",
               "or ramdisk associated with this AMI are not in the target region, AMI",
               "registration will fail.",
               "You can use the ec2-migrate-manifest tool to update your manifest file",
               "with a kernel and ramdisk that exist in the target region.",
              ].join("\n")
    unless warn_confirm(message)
      raise EC2StopExecution.new()
    end
  end
  
  #------------------------------------------------------------------------------#

  def get_s3_conn(s3_url, user, pass, method)
    EC2::Common::S3Support.new(s3_url, user, pass, method, @debug)
  end

  #------------------------------------------------------------------------------#
  
  #
  # Get parameters and display help or manual if necessary.
  #
  def upload_bundle(url,
                    bucket,
                    user,
                    pass,
                    location,
                    manifest_file,
                    retry_stuff,
                    part,
                    directory,
                    acl,
                    skipmanifest)
    begin
      # Get the S3 URL.
      s3_uri = URI.parse(url)
      s3_url = uri2string(s3_uri)
      v2_bucket = check_bucket_name(bucket)
      s3_conn = get_s3_conn(s3_url, user, pass, (v2_bucket ? nil : :path))

      # Get current location and bucket location.
      bucket_location = get_bucket_location(s3_conn, bucket)

      # Load manifest.
      xml = File.open(manifest_file) { |f| f.read }
      manifest = ManifestV20071010.new(xml)
      
      # If we are uploading cross-region and have a kernel bundled in our AMI, warn.
      if cross_region?(location, bucket_location) and manifest.kernel_id
        warn_about_migrating()
      end
      
      # Create storage bucket if required.
      create_bucket(s3_conn, bucket, bucket_location, location, retry_stuff)
      
      # Upload AMI bundle parts.
      $stdout.puts "Uploading bundled image parts to the S3 bucket #{bucket} ..."
      get_part_info(manifest).each do |part_info|
        if part.nil? or (part_info[1] >= part)
          path = File.join(directory, part_info[0])
          upload(s3_conn, bucket, part_info[0], path, acl, retry_stuff)
          $stdout.puts "Uploaded #{part_info[0]}"
        else
          $stdout.puts "Skipping #{part_info[0]}"
        end
      end
      
      # Encrypt and upload manifest.
      unless skipmanifest
        $stdout.puts "Uploading manifest ..."
        upload(s3_conn, bucket, File::basename(manifest_file), manifest_file, acl, retry_stuff)
        $stdout.puts "Uploaded manifest."
      else
        $stdout.puts "Skipping manifest."
      end
      
      $stdout.puts 'Bundle upload completed.'
    rescue EC2::Common::HTTP::Error => e
      $stderr.puts e.backtrace if @debug
      raise S3Error.new(e.message)
    end
  end

  #------------------------------------------------------------------------------#
  # Overrides
  #------------------------------------------------------------------------------#

  def get_manual()
    UPLOAD_BUNDLE_MANUAL
  end

  def get_name()
    UPLOAD_BUNDLE_NAME
  end

  def main(p)
    upload_bundle(p.url,
                  p.bucket,
                  p.user,
                  p.pass,
                  p.location,
                  p.manifest,
                  p.retry,
                  p.part,
                  p.directory,
                  p.acl,
                  p.skipmanifest)
  end

end

#------------------------------------------------------------------------------#
# Script entry point. Execute only if this file is being executed.
if __FILE__ == $0
  BundleUploader.new().run(UploadBundleParameters)
end
