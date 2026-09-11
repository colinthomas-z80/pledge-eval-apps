#!/bin/sh

# There are a vast number of variations in the process of
# building a mosaic from a set of astronomical images.
# This example explores one of them, but one that has the
# advantage of requiring no starting data (it retrieves
# that, so does require a network connection).  Once the
# data is retrieved -- by whatever means -- the rest of 
# the processing is fairly boilerplate.  The only major
# variation would be to skip all the background matching
# if your images already have well-calibrated backgrounds.

# This script should really be run in an empty directory
# but at least the working directories it uses can't have
# any extraneous files.

rm -rf projected diffs corrected
mkdir  projected diffs corrected


# Much of the processing is based on the "header" for the
# the output mosaic.  Here we build one as a simple square
# on the sky but you are free to come up with your own.

mHdr "NGC 3372" 2.0 region.hdr


# To go along with this, we need a set of input images.  Here
# we get that list from a remote server but you may have your
# own data or way of getting it.  Remote archive image lists
# are not always a good match for the region we want, so here
# we pad the request, then check it against the header to get
# a proper subset.

# mArchiveList 2mass k "NGC 3372" 2.8 2.8 archive.tbl
# mCoverageCheck archive.tbl remote.tbl -header region.hdr


# # Now we can start the data processing.  First retrieve the
# # archive data.

# mArchiveExec -p raw remote.tbl
mImgtbl raw rimages.tbl


# Then reproject them all to match the header.

mProjExec -q -p raw rimages.tbl region.hdr projected stats.tbl
mImgtbl projected pimages.tbl


# As the firt step in ajusting the backgrounds, find all the
# overlaps and fit the pairwise background offsets.

mOverlaps pimages.tbl diffs.tbl
mDiffFitExec -p projected diffs.tbl region.hdr diffs fits.tbl


# For a global background adjustment solution, model the 
# set of difference offsets.

mBgModel pimages.tbl fits.tbl corrections.tbl


# And apply the corrections to each individual image.

mBgExec -p projected pimages.tbl corrections.tbl corrected
mImgtbl corrected cimages.tbl


# Finally, coadd the backgroun-corrected, reprojected images
# into a mosaic.

mAdd -p corrected cimages.tbl region.hdr mosaic.fits


# And make a PNG image of the result.

mViewer -ct 1 -gray mosaic.fits -2s max gaussian-log -out mosaic.png

