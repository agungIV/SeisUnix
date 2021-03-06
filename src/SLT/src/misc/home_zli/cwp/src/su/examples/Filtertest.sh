#! /bin/sh
# Create filter panels for an input cmp gather
# Authors: Jack, Ken
# NOTE: Comment lines preceeding user input start with  #!#
set -x

#!# Set file etc.
input=cdpby100
cdp=501		# pick a cdp -- also used for naming output files
fold=30
space=6		# 6 null traces between panels

#!# Determine range of cutoff frequencies
lowmin=3 lowmax=12
j=0  # test panel number
lowratio=0.8 highratio=1.2
high=12 dlow=3 dhigh=12 expand=2


### Determine ns and dt from data (for sunull)
nt=`sugethw ns <$input | sed 1q | sed 's/.*ns=//'`
dt=`sugethw dt <$input | sed 1q | sed 's/.*dt=//'`

### Convert dt to seconds from header value in microseconds
dt=`bc -l <<-END
	$dt / 1000000
END`


### Label output according to cdp number and get the cdp
filpanel=fil.$cdp
filparams=filparams.$cdp
suwind <$input key=cdp min=$cdp max=$cdp count=$fold >cdp.$cdp



### Loop over frequencies
>$filpanel  # zero output file

cp cdp.$cdp $filpanel	# first (i.e. zeroth) panel is w/o any filter
sunull ntr=$space nt=$nt dt=$dt >>$filpanel

echo "Test f1 f2 f3 f4" >$filparams
low=$lowmin
while [ $low -le $lowmax ]
do
	j=`expr $j + 1`
	low1=`bc -l <<-END
		$lowratio * $low
	END`
	high1=`bc -l <<-END
		$highratio * $high
	END`

	suband <cdp.$cdp f1=$low1 f2=$low f3=$high f4=$high1 >>$filpanel
	sunull ntr=$space nt=$nt dt=$dt >>$filpanel

	echo "$j   $low1 $low $high $high1" >>$filparams
	low=`bc -l <<-END
		$low + $dlow
	END`
	high=`bc -l <<-END
		$high + $dhigh
	END`
	dlow=`bc -l <<-END
		$expand * $dlow
	END`
	dhigh=`bc -l <<-END
		$expand * $dhigh
	END`
done

echo "The parameter values are recorded in $filparams"


### Plot filter panels
f2=0
d2=`bc -l <<-END
	1/($fold + $space)
END`

sugain <$filpanel tpow=2.0 gpow=.5 |
suxwigb f2=$f2 d2=$d2 perc=99 title="File: $filpanel  Filter Test "  \
	label1="Time (s)"  label2="Filter Number" & 
