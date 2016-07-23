Phy/WirelessPhy set CSThresh 1.7615e-10
#Phy/WirelessPhy set Pt_ 0.282

set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy          ;# network interface type
set val(mac)          Mac/802_11	               ;# MAC type
set val(rp)           DSDV                      ;# ad-hoc routing protocol 
set val(nn)           3                        ;# number of mobilenodes
set val(tp)           0.282                    ;#transmit power of nodes

set ns [new Simulator]

set tracefd     [open simple.tr w]
$ns trace-all $tracefd 

set nf [open out.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
        global ns nf
        $ns flush-trace
        #Close the NAM trace file
        close $nf
        #Execute NAM on the trace file
        exec nam out.nam &
        exit 0
}

set topo       [new Topography]
$topo load_flatgrid 500 500

create-god $val(nn)



# Configure nodes
        $ns node-config -adhocRouting $val(rp) \
                         -llType $val(ll) \
                         -macType $val(mac) \
                         -ifqType $val(ifq) \
                         -ifqLen $val(ifqlen) \
                         -antType $val(ant) \
                         -propType $val(prop) \
                         -phyType $val(netif) \
                         -topoInstance $topo \
                         -channelType $val(chan) \
                         -agentTrace ON \
                         -routerTrace ON \
                         -macTrace OFF \
                         -movementTrace OFF \
		         -txPower $val(tp) \
			 -IncomingErrProc 


set n1 [$ns node] 
set n2 [$ns node] 
set n3 [$ns node] 

$n1 random-motion 0 
$n2 random-motion 0 
$n3 random-motion 0 

$n1 set X 50.0
$n1 set Y 50.0
$n1 set Z 0
$n2 set X 250.0
$n2 set Y 50.0
$n2 set Z 0
$n3 set X 450.0
$n3 set Y 50.0
$n3 set Z 0



$ns color 1 Blue
$ns color 2 Red

proc UniformErr {} {
set err [new ErrorModel]
$err unit packet
$err set rate_ 0.01
return $err
}


$ns duplex-link $n1 $n2 1Mb 10ms DropTail   
$ns duplex-link $n3 $n2 1Mb 10ms DropTail 

$ns duplex-link-op $n1 $n2 orient right 
$ns duplex-link-op $n2 $n3 orient right   

#Create a UDP agent and attach it to node n1
set udp0 [new Agent/UDP]
$ns attach-agent $n1 $udp0
$udp0 set class_ 1

# Create a CBR traffic source and attach it to udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 1500
$cbr0 set interval_ 0.003
$cbr0 attach-agent $udp0

#Create a UDP agent and attach it to node n3
set udp1 [new Agent/UDP]
$ns attach-agent $n3 $udp1
$udp1 set class_ 2

# Create a CBR traffic source and attach it to udp1
set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 1500
$cbr1 set interval_ 0.003
$cbr1 attach-agent $udp1


set sink1 [new Agent/LossMonitor]
$ns attach-agent $n2 $sink1

$ns connect $udp0 $sink1
$ns connect $udp1 $sink1



$ns at 0.5 "$cbr0 start"
$ns at 4.5 "$cbr0 stop"
$ns at 0.5 "$cbr1 start"
$ns at 4.5 "$cbr1 stop"


$ns at 10.0 "$n1 reset"
$ns at 10.0 "$n2 reset"
$ns at 10.0 "$n3 reset"

$ns at 10.0 "stop"

proc stop {} {
    global ns tracefd
    close $tracefd
}


puts "Starting Topology 1"
$ns run
