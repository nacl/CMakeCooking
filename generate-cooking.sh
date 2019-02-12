#
# Copyright 2018 Jesse Haber-Kucharsky
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script is used to pack up the development files for cmake-cooking into a single file (cooking.sh) that can easily
# be deployed to projects.
#
# Thanks to
# https://superuser.com/questions/440013/how-to-replace-part-of-a-text-file-between-markers-with-another-text-file for
# the sed magic.

set -e

marker_begin='^### BEGIN GENERATED FILE$'
marker_end='^### END GENERATED FILE$'

sed -e "/$marker_begin/,/$marker_end/{ /$marker_begin/{p; r Cooking.cmake
        }; /$marker_end/p; d }" cooking.sh.in > cooking.sh

chmod +x cooking.sh
