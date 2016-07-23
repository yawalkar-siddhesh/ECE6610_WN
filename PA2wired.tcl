# Copyright (c) 1999 Regents of the University of Southern California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#      This product includes software developed by the Computer Systems
#      Engineering Group at Lawrence Berkeley Laboratory.
# 4. Neither the name of the University nor of the Laboratory may be used
#    to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
# wireless1.tcl
# A simple example for wireless simulation

# ======================================================================
# Define options
# ======================================================================



Phy/WirelessPhy set CSThresh 1.7615e-10
global defaultRNG 
$defaultRNG seed 0 



set val(mac)        Mac/802_11
set val(nn)             3             ;# how many nodes are simulated
set val(stop)          100        ;# simulation time


# =====================================================================
# Main Program
# ======================================================================

#
# Initialize Global Variables
#

# create simulator instance

set ns_		[new Simulator]


# create trace object for ns and nam

set tracefd		[open wired-out.tr w]
set namtrace    [open wired-out.nam w]

if { $::argc ne 3 } {
	puts "Please pass in 3 inputs in the following order: error bigCW(0 or 1) Sack(0 or 1)"
	exit 0
}

set bigCW [lindex $argv 1]
set Sack [lindex $argv 2]
set Error [lindex $argv 0]
global Error
puts "Error is : $Error"

$ns_ trace-all $tracefd
$ns_ namtrace-all $namtrace



#Define a 'finish' procedure		
proc finish {} {
        global ns_ namtrace
        $ns_ flush-trace
        #Close the NAM trace file
        close $namtrace
        #Execute NAM on the trace file
      #  exec nam wireless1-out.nam &
        exit 0
}


#
# Create God
#
set god_ [create-god $val(nn)]

#
# define how node should be created
#

#global node setting


$ns_ node-config -macType $val(mac) 


#
#  Create the specified number of nodes [$val(nn)] and "attach" them
#  to the channel. 

for {set i 0} {$i < $val(nn) } {incr i} {
	set node_($i) [$ns_ node]	
}

$ns_ color 1 Blue
$ns_ color 2 Red



#SETUP the connections of the nodes (which nodes are connected to what)
#also specifies the speed and delay of the links
$ns_ duplex-link $node_(0) $node_(1) 20Mb 2ms DropTail   
$ns_ duplex-link $node_(1) $node_(2) 8Mb  5ms DropTail    #Vary this parameter 

$ns_ queue-limit $node_(1) $node_(2) 10  

#Create a TCP agent and attach it to node n0
if {$Sack == 1} then {set tcp0 [new Agent/TCP/Sack1]} else {set tcp0 [new Agent/TCP/Reno]}

if {$bigCW == 1} {$tcp0 set windowInit_ 4}
		
$tcp0 set window_ 8000 #max CW size
$tcp0 set fid_ 1
$tcp0 set packetSize_ 552

$ns_ attach-agent $node_(0) $tcp0

# Create a ftp traffic source and attach it to tcp0 (actual traffic)
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0
$ftp0 set type_ FTP

#No need to attach agent to node1 (only routes traffic)

# Create a regular TCP sink or a TCP Sack sink and attach it to node 2
if {$Sack == 1} then {set sink2 [new Agent/TCPSink/Sack1]} else {set sink2 [new Agent/TCPSink]}
$ns_ attach-agent $node_(2) $sink2

# Indicate the sender and the intended receiver of the traffic
$ns_ connect $tcp0 $sink2


# create a random variable that follows the uniform distribution
set loss_random_variable [new RandomVariable/Uniform]
$loss_random_variable set min_ 0 # the range of the random variable;
$loss_random_variable set max_ 100
set loss_module [new ErrorModel] ;# create the error model;
$loss_module drop-target [new Agent/Null]; #a null agent where the dropped packets go to
$loss_module set rate_ $Error ;# error rate will then be (0.1 = 10 / (100 - 0));
$loss_module ranvar $loss_random_variable ;# attach the random variable to loss module; 

if {$Error == 0 } then {puts "ERROR = 0% "} else {$ns_ lossmodel $loss_module $node_(1) $node_(2)}

#
# Tell nodes when the simulation ends
#


$ns_ at 0.5 "$ftp0 start"
$ns_ at 99.5 "$ftp0 stop"



$ns_ at 99.9 "$node_(0) reset"
$ns_ at 99.9  "$node_(1) reset"
$ns_ at 99.9 "$node_(2) reset"


#Call the finish procedure after 5 seconds of simulation time
$ns_ at 100.0 "finish"

##################################################
  ## Obtain CWND from TCP agent
  ##################################################

# procedure to plot the congestion window
proc plotWindow {tcpSource outfile} {
   global ns_
   set now [$ns_ now]
   set cwnd [$tcpSource set cwnd_]

# the data is recorded in a file called congestion.xg 
# can be plotted using xgraph or gnuplot
   puts  $outfile  "$now $cwnd"
   $ns_ at [expr $now+0.05] "plotWindow $tcpSource  $outfile"
}


set outfile [open  "congestion.xg"  w]
$ns_  at  0.0  "plotWindow $tcp0  $outfile"

######################################################
puts "Starting Simulation..."
$ns_ run
