class Chef

  # This module exists to hide conflicting constant names from the DSL.
  # Hopefully we'll have a better/prettier/more sustainable solution in the
  # future, but for now this will fix a regression introduced in Chef 0.10.10
  # (conflict with the Win32 namespace)
  module ReservedNames
  end
end
