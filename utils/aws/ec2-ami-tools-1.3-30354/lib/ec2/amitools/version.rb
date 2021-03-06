# Copyright 2008 Amazon.com, Inc. or its affiliates.  All Rights
# Reserved.  Licensed under the Amazon Software License (the
# "License").  You may not use this file except in compliance with the
# License. A copy of the License is located at
# http://aws.amazon.com/asl or in the "license" file accompanying this
# file.  This file is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
# the License for the specific language governing permissions and
# limitations under the License.

require 'ec2/amitools/manifestv20071010'

module EC2Version
  MANIFEST_CLASS = ManifestV20071010
  MANIFEST_VERSION = MANIFEST_CLASS.version
  PKG_NAME = 'ec2-ami-tools'
  PKG_VERSION = '1.3'
  PKG_RELEASE = '30354'

  COPYRIGHT_NOTICE = <<CNOTICE
Copyright 2008 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
Licensed under the Amazon Software License (the "License").  You may not use
this file except in compliance with the License. A copy of the License is
located at http://aws.amazon.com/asl or in the "license" file accompanying this
file.  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
CNOTICE
  
  def self.version_copyright_string()
    "#{PKG_VERSION}-#{PKG_RELEASE} #{MANIFEST_VERSION}\n\n" + COPYRIGHT_NOTICE + "\n"
  end
end
