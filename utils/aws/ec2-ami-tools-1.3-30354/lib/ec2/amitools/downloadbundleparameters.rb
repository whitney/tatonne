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

class DownloadBundleParameters < ParametersBase

  BUCKET_DESCRIPTION      = "The bucket to download the bundle from."
  PREFIX_DESCRIPTION      = "The filename prefix for bundled AMI files. Defaults to 'image'."
  URL_DESCRIPTION         = "The S3 service URL. Defaults to https://s3.amazonaws.com."
  DIRECTORY_DESCRIPTION   = ['The directory into which to download the bundled AMI parts.',
                             "Defaults to the current working directory."]
  MANIFEST_DESCRIPTION    = ["The local manifest filename. Required only for manifests that",
                             "pre-date the version 3 manifest file format."]
  RETRY_DESCRIPTION       = "Automatically retry failed downloads."
  
  attr_accessor :bucket,
                :manifest,
                :prefix,
                :user,
                :pass,
                :privatekey,
                :directory,
                :retry,
                :url
    
  #----------------------------------------------------------------------------#

  def mandatory_params()
    on('-b', '--bucket BUCKET', String, BUCKET_DESCRIPTION) do |bucket|
      @bucket = bucket
    end
    
    on('-a', '--access-key USER', String, USER_DESCRIPTION) do |user|
      @user = user
    end
    
    on('-s', '--secret-key PASSWORD', String, PASS_DESCRIPTION) do |pass|
      @pass = pass
    end

    on('-k', '--privatekey KEY', String, USER_PK_PATH_DESCRIPTION) do |privatekey|
      assert_file_exists(privatekey, '--privatekey')
      @privatekey = privatekey
    end
  end

  #----------------------------------------------------------------------------#

  def optional_params()
    on('-m', '--manifest FILE', String, *MANIFEST_DESCRIPTION) do |manifest|
      @manifest = manifest
    end
    
    on('-p', '--prefix PREFIX', String, PREFIX_DESCRIPTION) do |prefix|
      @prefix = prefix
    end
    
    on('-d', '--directory DIRECTORY', String, *DIRECTORY_DESCRIPTION) do |directory|
      assert_directory_exists(directory, '--directory')
      @directory = directory
    end
    
    on('--retry', RETRY_DESCRIPTION) do
      @retry = true
    end
    
    on('--url URL', String, URL_DESCRIPTION) do |url|
      @url = url
    end
  end
  
  #----------------------------------------------------------------------------#

  def validate_params()
    raise MissingMandatory.new('--bucket') unless @bucket
    raise MissingMandatory.new('--access-key') unless @user
    raise MissingMandatory.new('--secret-key') unless @pass
    raise MissingMandatory.new('--privatekey') unless @privatekey
    raise InvalidCombination.new('--prefix', '--manifest') if (@prefix and @manifest)
  end

  #----------------------------------------------------------------------------#

  def set_defaults()
    @directory = Dir::pwd() unless @directory
    @url = 'https://s3.amazonaws.com' unless @url
    @prefix = @manifest.split('.')[0..-2].join('.') if (@manifest)
    @prefix = 'image' unless @prefix
    @manifest = "#{@prefix}.manifest.xml" unless @manifest
  end
  
end
