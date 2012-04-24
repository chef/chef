class Chef
  class Provider
    class Package
      class Yum
        class RPMUtils
          class << self

            # RPM::Version version_parse equivalent
            def version_parse(evr)
              return if evr.nil?

              epoch = nil
              # assume this is a version
              version = evr
              release = nil

              lead = 0
              tail = evr.size

              if evr =~ %r{^([\d]+):}
                epoch = $1.to_i
                lead = $1.length + 1
              elsif evr[0].ord == ":".ord
                epoch = 0
                lead = 1
              end

              if evr =~ %r{:?.*-(.*)$}
                release = $1
                tail = evr.length - release.length - lead - 1

                if release.empty?
                  release = nil
                end
              end

              version = evr[lead,tail]
              if version.empty?
                version = nil
              end

              [ epoch, version, release ]
            end

            # verify
            def isalnum(x)
              isalpha(x) or isdigit(x)
            end

            def isalpha(x)
              v = x.ord
              (v >= 65 and v <= 90) or (v >= 97 and v <= 122)
            end

            def isdigit(x)
              v = x.ord
              v >= 48 and v <= 57
            end

            # based on the reference spec in lib/rpmvercmp.c in rpm 4.9.0
            def rpmvercmp(x, y)
              # easy! :)
              return 0 if x == y

              if x.nil?
                x = ""
              end

              if y.nil?
                y = ""
              end

              # not so easy :(
              #
              # takes 2 strings like
              #
              # x = "1.20.b18.el5"
              # y = "1.20.b17.el5"
              #
              # breaks into purely alpha and numeric segments and compares them using
              # some rules
              #
              # * 10 > 1
              # * 1 > a
              # * z > a
              # * Z > A
              # * z > Z
              # * leading zeros are ignored
              # * separators (periods, commas) are ignored
              # * "1.20.b18.el5.extrastuff" > "1.20.b18.el5"

              x_pos = 0                # overall string element reference position
              x_pos_max = x.length - 1 # number of elements in string, starting from 0
              x_seg_pos = 0            # segment string element reference position
              x_comp = nil             # segment to compare

              y_pos = 0
              y_seg_pos = 0
              y_pos_max = y.length - 1
              y_comp = nil

              while (x_pos <= x_pos_max and y_pos <= y_pos_max)
                # first we skip over anything non alphanumeric
                while (x_pos <= x_pos_max) and (isalnum(x[x_pos]) == false)
                  x_pos += 1 # +1 over pos_max if end of string
                end
                while (y_pos <= y_pos_max) and (isalnum(y[y_pos]) == false)
                  y_pos += 1
                end

                # if we hit the end of either we are done matching segments
                if (x_pos == x_pos_max + 1) or (y_pos == y_pos_max + 1)
                  break
                end

                # we are now at the start of a alpha or numeric segment
                x_seg_pos = x_pos
                y_seg_pos = y_pos

                # grab segment so we can compare them
                if isdigit(x[x_seg_pos].ord)
                  x_seg_is_num = true

                  # already know it's a digit
                  x_seg_pos += 1

                  # gather up our digits
                  while (x_seg_pos <= x_pos_max) and isdigit(x[x_seg_pos])
                    x_seg_pos += 1
                  end
                  # copy the segment but not the unmatched character that x_seg_pos will
                  # refer to
                  x_comp = x[x_pos,x_seg_pos - x_pos]

                  while (y_seg_pos <= y_pos_max) and isdigit(y[y_seg_pos])
                    y_seg_pos += 1
                  end
                  y_comp = y[y_pos,y_seg_pos - y_pos]
                else
                  # we are comparing strings
                  x_seg_is_num = false

                  while (x_seg_pos <= x_pos_max) and isalpha(x[x_seg_pos])
                    x_seg_pos += 1
                  end
                  x_comp = x[x_pos,x_seg_pos - x_pos]

                  while (y_seg_pos <= y_pos_max) and isalpha(y[y_seg_pos])
                    y_seg_pos += 1
                  end
                  y_comp = y[y_pos,y_seg_pos - y_pos]
                end

                # if y_seg_pos didn't advance in the above loop it means the segments are
                # different types
                if y_pos == y_seg_pos
                  # numbers always win over letters
                  return x_seg_is_num ? 1 : -1
                end

                # move the ball forward before we mess with the segments
                x_pos += x_comp.length # +1 over pos_max if end of string
                y_pos += y_comp.length

                # we are comparing numbers - simply convert them
                if x_seg_is_num
                  x_comp = x_comp.to_i
                  y_comp = y_comp.to_i
                end

                # compares ints or strings
                # don't return if equal - try the next segment
                if x_comp > y_comp
                  return 1
                elsif x_comp < y_comp
                  return -1
                end

                # if we've reached here than the segments are the same - try again
              end

              # we must have reached the end of one or both of the strings and they
              # matched up until this point

              # segments matched completely but the segment separators were different -
              # rpm reference code treats these as equal.
              if (x_pos == x_pos_max + 1) and (y_pos == y_pos_max + 1)
                return 0
              end

              # the most unprocessed characters left wins
              if (x_pos_max - x_pos) > (y_pos_max - y_pos)
                return 1
              else
                return -1
              end
            end

          end # self
        end # RPMUtils
      end
    end
  end
end
