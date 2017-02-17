str: "192.168.1.137" constant: IP
9091 constant: PORT
str: "/metrics/job/flowerlogger" constant: URL

512 buffer: line-buf
variable: socket

: 2dip ( x y quot -- x y ) swap { dip } dip ;
: tri* ( x y z p q r -- ) { { 2dip } dip dip } dip execute ;
: tri@ ( x y z q -- ) dup dup tri* ;

: connect ( -- ) PORT IP TCP netcon-connect socket ! ;
: dispose ( -- ) socket @ netcon-dispose ;

: write ( str -- ) socket @ swap netcon-write ;
: n>str ( n -- str ) line-buf swap >str line-buf ;
: lf ( -- ) str: "\n" ;
: write-header ( -- )
   str: "PUT " URL str: " HTTP/1.1\r\n" { write } tri@
   str: "Host: " IP str: ":" { write } tri@
   PORT n>str write
   str: "\r\n" write
   str: "Content-Length: 128" write \ hack
   str: "\r\n\r\n" write ;
: write-soil-humidity ( -- )
   str: "soil_humidity " write
   adc-read  n>str write  lf write ;
: write-temp-and-humidity ( -- )
   dht-measure
   { str: "temperature " write  n>str write  lf write }
   { str: "humidity "    write  n>str write  lf write }
   bi* ;

: send-measurements ( -- )
   connect
   write-header write-soil-humidity write-temp-and-humidity
   dispose ;

: timed-pause ( -- neg-diff ) ms@ pause ms@ - ;
: pause-ms ( ms -- ) begin dup 0 > while timed-pause + repeat drop ;

: measure-loop ( task -- )
   activate
      begin  15000 pause-ms  send-measurements  again
   deactivate ;

0 task: measure-task

: measure-start ( -- ) multi measure-task measure-loop ;

repl-start
measure-start
