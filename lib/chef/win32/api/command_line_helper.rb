#
# Author:: Kapil Chouhan <kapil.chouhan@msystechnologies.com>
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../api"

class Chef
  module ReservedNames::Win32
    module API
      module CommandLineHelper
        # extend Chef::ReservedNames::Win32
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib "Shell32"

=begin
LPWSTR * CommandLineToArgvW(
  LPCWSTR lpCmdLine,
  int     *pNumArgs
);
=end

        safe_attach_function :command_line_to_argv_w, :CommandLineToArgvW, %i{pointer pointer}, :pointer

        ffi_lib "Kernel32"

=begin
LPSTR GetCommandLineA();
=end

        safe_attach_function :get_command_line, :GetCommandLineA, [], :pointer

=begin
HLOCAL LocalFree(
  _Frees_ptr_opt_ HLOCAL hMem
);
=end

        safe_attach_function :local_free, :LocalFree, [:pointer], :pointer

        ###############################################
        # Helpers
        ###############################################

        # It takes the supplied string and splits it into an array.
        def command_line_to_argv_w_helper(args)
          arguments_list = []
          argv = args.to_wstring
          result = get_command_line
          argc = FFI::MemoryPointer.new(:int)

          # Parses a Unicode command line string
          # It is return an array of pointers to the command line arguments.
          # Along with a count of such arguments
          result = command_line_to_argv_w(argv, argc)
          str_ptr = result.read_pointer
          offset = 0
          number_of_agrs = argc.read_int
          number_of_agrs.times do
            new_str_pointer = str_ptr.+(offset)
            argument = new_str_pointer.read_wstring
            arguments_list << argument
            offset = offset + argument.length * 2 + 2
          end
          local_free(result)
          arguments_list
        end
      end
    end
  end
end
