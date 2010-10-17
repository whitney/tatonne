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

class DeleteBundleParameters < ParametersBase
    
  BUCKET_DESCRIPTION = "The bucket containing the bundled AMI."  
  MANIFEST_DESCRIPTION = "The path to the unencrypted manifest file."  
  PREFIX_DESCRIPTION = "The bundled AMI part filename prefix."  
  RETRY_DESCRIPTION = "Automatically retry failed deletes. Use with caution."  
  URL_DESCRIPTION = "The S3 service URL. Defaults to https://s3.amazonaws.com."  
  YES_DESCRIPTION = "Automatically answer 'y' without asking."
  CLEAR_DESCRIPTION = "Delete the bucket if empty. Not done by default."
  
  attr_accessor :bucket,
                :manifest,
                :prefix,
                :user,
                :pass,
                :retry,
                :url,
                :yes,
                :clear
    
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
  end
  
  #----------------------------------------------------------------------------#

  def optional_params()
    on('-m', '--manifest PATH', String, MANIFEST_DESCRIPTION) do |manifest|
      assert_file_exists(manifest, '--manifest')
      @manifest = manifest
    end
    
    on('-p', '--prefix PREFIX', String, PREFIX_DESCRIPTION) do |prefix|
      @prefix = prefix
    end
    
    on('--clear', CLEAR_DESCRIPTION) do
      @clear = true
    end
    
    on('--retry', RETRY_DESCRIPTION) do
      @retry = true
    end
    
    on('--url URL', String, URL_DESCRIPTION) do |url|
      @url = url
    end
    
    on('-y', '--yes', YES_DESCRIPTION) do
      @yes = true
    end
  end

  #----------------------------------------------------------------------------#

  def validate_params()
    raise MissingMandatory.new('--bucket') unless @bucket
    raise MissingMandatory.new('--manifest or --prefix') unless @manifest or @prefix
    raise MissingMandatory.new('--access-key') unless @user
    raise MissingMandatory.new('--secret-key') unless @pass
    raise InvalidCombination.new('--prefix', '--manifest') if (@prefix and @manifest)
  end

  #----------------------------------------------------------------------------#

  def set_defaults()
    @url ||= 'https://s3.amazonaws.com'
    @clear ||= false
  end

end
