# Author:: Chef Software Inc.
# Copyright:: Copyright (c) Chef Software Inc.
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
# == Background
#
# On Windows, Reline's process_key_event emits an ESC byte (0x1B) before every
# character when the :ALT control key flag is set.  This is correct for true
# Alt key combos (Meta sequences), but AltGr on European keyboards – most
# notably German layouts – is reported by Windows as Ctrl+Alt (RIGHT_CTRL +
# RIGHT_ALT pressed simultaneously).  Characters that require AltGr, such as
# { } [ ] @ ~ | \, therefore receive both :CTRL and :ALT flags, causing Reline to
# emit an ESC prefix.  In a terminal the result looks like ^[{ instead of {.
#
# The corrupt input leaves IRB's parser in an open-string/block state which
# re-draws continuation prompts endlessly when multi-line blocks are pasted,
# making chef-shell unusable for German (and many other European) keyboard users.
#
# == Fix
#
# Only emit the ESC Meta prefix when :ALT is set WITHOUT :CTRL.  When both
# flags are present the keypress is AltGr-originated and the raw character
# bytes are sufficient and correct.
#
# == Affected versions
#
# Verified against Reline <= 0.3.x (shipped with Ruby 3.1.x in chef-foundation).
# The issue was resolved upstream in Reline 0.3.2 / irb 1.6.2 (Ruby 3.2+),
# so the patch is guarded to apply only when the installed Reline version is
# affected.
#
# == References
#
# * Upstream report:  https://github.com/ruby/reline/issues/475
# * Chef PR #9267   (Ruby 2.7 IRB fixes, introduced multiline/singleline wiring)
# * Chef PR #14919  (Prompt consistency fix for left-arrow on Ruby 3.1/3.2)
# * Chef PR #15336  (IRB @ALIASES removal compat)

if Gem.win_platform? && defined?(Reline::Windows)

  # Only patch versions where the bug is present.  Reline 0.3.2 fixed it
  # upstream.  Gem::Version comparison is safe even when reline is a stdlib
  # default gem without a Gemspec entry in loaded_specs.
  reline_version = begin
    Gem::Version.new(Reline::VERSION)
  rescue StandardError
    Gem::Version.new("0")
  end

  if reline_version < Gem::Version.new("0.3.2")
    Chef::Log.debug("chef-shell: applying Reline::Windows AltGr monkey patch (reline #{Reline::VERSION})")

    class Reline::Windows
      class << self
        # Reopen process_key_event and change only the ESC-emission guard.
        # All other behaviour – surrogate pair handling, KEY_MAP matching, bare
        # control-key suppression – is preserved verbatim from the original.
        def process_key_event(repeat_count, virtual_key_code, virtual_scan_code, char_code, control_key_state)

          # ---- surrogate pair handling (unchanged) --------------------------------
          if 0xD800 <= char_code && char_code <= 0xDBFF
            @@hsg = char_code
            return
          end

          if 0xDC00 <= char_code && char_code <= 0xDFFF
            if @@hsg
              char_code = 0x10000 + (@@hsg - 0xD800) * 0x400 + char_code - 0xDC00
              @@hsg = nil
            else
              return # low-surrogate without preceding high-surrogate – ignore
            end
          else
            @@hsg = nil # discard stale high-surrogate
          end
          # -------------------------------------------------------------------------

          key = KeyEventRecord.new(virtual_key_code, char_code, control_key_state)

          # KEY_MAP takes priority (arrow keys, Delete, Home, End, Tab, etc.)
          match = KEY_MAP.find { |args,| key.matches?(**args) }
          unless match.nil?
            @@output_buf.concat(match.last)
            return
          end

          # Suppress bare modifier-only keypresses (no printable character)
          return if key.char_code == 0 && key.control_keys.any?

          # ---- THE FIX -----------------------------------------------------------
          # Original:  @@output_buf.push("\e".ord) if key.control_keys.include?(:ALT)
          #
          # AltGr on European keyboards reports as Ctrl+Alt (both :CTRL and :ALT
          # present).  Only emit the ESC Meta prefix when Alt is pressed WITHOUT
          # Ctrl – i.e. a genuine Meta/Alt sequence, not an AltGr character.
          alt_without_ctrl = key.control_keys.include?(:ALT) && !key.control_keys.include?(:CTRL)
          @@output_buf.push("\e".ord) if alt_without_ctrl
          # -------------------------------------------------------------------------

          @@output_buf.concat(key.char.bytes)
        end
      end
    end
  end
end
