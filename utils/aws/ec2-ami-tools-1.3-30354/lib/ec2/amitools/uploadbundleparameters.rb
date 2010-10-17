# Copyright 2008 Amazon.com, Inc. or its affiliates.  All Rights
# Reserved.  Licensed under the Amazon Software License (the
# "License").  You may not use this file except in compliance with the
# License. A copy of the License is located at
# http://aws.amazon.com/asl or in the "license" file accompanying this
# file.  This file is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
# the License for the specific language governing permissions and
# limitations under the License.

require 'ec2/amitools/parameters_base'

#------------------------------------------------------------------------------#

class UploadBundleParameters < ParametersBase

  BUCKET_DESCRIPTION = "The bucket to upload the bundle to. Created if nonexistent."
  MANIFEST_DESCRIPTION = "The path to the manifest file."
  ACL_DESCRIPTION = ["The access control list policy [\"public-read\" | \"aws-exec-read\"].",
                         "Defaults to \"aws-exec-read\"."]
  DIRECTORY_DESCRIPTION = ["The directory containing the bundled AMI parts to upload.",
                      "Defaults to the directory containing the manifest."]
  PART_DESCRIPTION = "Upload the specified part and upload all subsequent parts."
  RETRY_DESCRIPTION = "Automatically retry failed uploads."
  SKIP_MANIFEST_DESCRIPTION = "Do not upload the manifest."
  LOCATION_DESCRIPTION = "The location of the bucket to upload to [EU,US]."
  URL_DESCRIPTION = "The S3 service URL. Defaults to https://s3.amazonaws.com."
  
  attr_accessor :bucket,
                :manifest,
                :user,
                :pass,
                :acl,
                :directory,
                :part,
                :retry,
                :skipmanifest,
                :location,
                :url

  #----------------------------------------------------------------------------#

  def mandatory_params()
    on('-b', '--bucket BUCKET', String, BUCKET_DESCRIPTION) do |bucket|
      @bucket = bucket
    end
    
    on('-m', '--manifest PATH', String, MANIFEST_DESCRIPTION) do |manifest|
      assert_file_exists(manifest, '--manifest')
      @manifest = manifest
    end

    on('-a', '--access-key USER', String, USER_DESCRIPTION) do |user|
      @user = user
    end
    
    on('-s', '--secret-key PASSWORD', String, PASS_DESCRIPTION) do |pass|
      @pass = pass
    end
  end

  #----------------------------------------------------------------------------#

  def optional_params()
    on('--acl ACL', String, *ACL_DESCRIPTION) do |acl|
      assert_option_in(acl, ['public-read', 'aws-exec-read'], '--acl')
      @acl = acl
    end
    
    on('-d', '--directory DIRECTORY', String, *DIRECTORY_DESCRIPTION) do |directory|
      assert_directory_exists(directory, '--directory')
      @directory = directory
    end

    on('--part PART', Integer, PART_DESCRIPTION) do |part|
      @part = part
    end
    
    on('--url URL', String, URL_DESCRIPTION) do |url|
      @url = url
    end
    
    on('--retry', RETRY_DESCRIPTION) do
      @retry = true
    end
    
    on('--skipmanifest', SKIP_MANIFEST_DESCRIPTION) do
      @skipmanifest = true
    end
    
    on('--location LOCATION', LOCATION_DESCRIPTION) do |location|
      @location = location
      @location = :unconstrained if @location == "US"
    end
  end

  #----------------------------------------------------------------------------#

  def validate_params()
    raise MissingMandatory.new('--bucket') unless @bucket
    raise MissingMandatory.new('--manifest') unless @manifest
    raise MissingMandatory.new('--access-key') unless @user
    raise MissingMandatory.new('--secret-key') unless @pass
  end

  #----------------------------------------------------------------------------#

  def set_defaults()
    @acl ||= 'aws-exec-read'
    @directory ||= File::dirname(@manifest)
    @url ||= 'https://s3.amazonaws.com'
  end

end
