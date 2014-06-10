import itertools
import sys

def main(lfname, rfname):
  lf = open(lfname, "r")
  rf = open(rfname, "r")
  
  depth = 1
# easy_mult dataset
#  classes = { 1 : (0, "00")
#            , 2 : (1, "10")
#            , 3 : (1, "11")
#            }
# E1_02 dataset
  classes = { 1 : (0, "00")
            , 2 : (1, "11")
            , 3 : (1, "10")
            }
# D2_015 dataset
#  classes   = { 1 : (1, "00")
#              , 2 : (0, "01")
#              , 3 : (1, "01")
#              }
  rindex    = 0
  i, errors = 0, 0
  for l, r in itertools.izip(lf, rf):
    lclass = int(l.split()[-1])

    rs = r.split()
    rdepth, rpath = int(rs[0]), rs[1]
    rpath  = ('0'*(depth-rdepth) + rpath[(depth-rdepth):]) # rotate right

    try:
      if classes[lclass] != (rdepth, rpath):
        print "%d: class %d vs " % (i, lclass),
        print (rdepth, rpath)
        errors += 1
    except KeyError:
      print '%d: marked as class %d, which is not in the dictionary' % (i, lclass)
    i += 1

  print "%d classification errors (%f%%) over %d data points." % (errors, 
                                                                  100*float(errors)/i, 
                                                                  i)

if __name__ == "__main__":
  if len(sys.argv) < 3:
    print '''
    Usage:
      python check.py left right
    '''
  else:
    main(sys.argv[1], sys.argv[2])
