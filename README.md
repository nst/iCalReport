#### Report the time spent on projects by reading iCal events

#### On Mac OS X 10.8 and later, use the Objective-C program.

    ./icalreport -h
    Usage: icalreport [-h] [-l] -c -f FROM_DATE -t TO_DATE
    
    Report the time spent on projects by reading iCal events.
    
      -h    show this help message and exit
      -l    use project name in event location (default is title)
      -c    calendar name
      -f    from date, yyyy-MM-dd format
      -t    to date, yyyy-MM-dd format

Sample run

    ./icalreport -c MyHours -f 2014-01-01 -f 2015-01-01
    ------------------------------------
    Report from 2014-01-01 to 2015-01-01
    ------------------------------------
    6.00 	 Project X
    6.00 	 Project y
    11.00 	 Project Z
    ------------------------------------
    Total duration: 23.00
    ------------------------------------

#### On Mac OS X 10.6 and 10.7, use the Python script.

	$ python icalreport.py --help
	Usage: icalreport.py [options]

	Options:
	  -h, --help  show this help message and exit
	  -c NAME     Name of the calendar (mandatory)
	  -m MONTH    Number of the month for which to report (default: current)
	  -u MONTH    Number of the month until which to report (default: current)
	  -w          Report for the current week
	  --lw        Report for last week
	  -t          Report for today
	  -s NUMBER   Skip items which are longer than this number of hours
	  -l          Look for projects in events locations (default: titles)

	  Purpose:
	    Report the time spent on projects by reading iCal events.

	  Example:
	    $ icalreport -c MyHours -m 9 -u 10 -l

	  Example:
	    $ icalreport -c MyHours -w -s 8

Sample run

	$ python icalreport.py -c "Heures_2009" -l
	------------------------------
	From 2009-09-01 to 2009-09-30
	------------------------------
	Annual Meeting       8.50
	MobiWalk             3.50
	MetaMin              11.50
	Memoria Mea 2        105.25
	------------------------------
	Total                128.75
	------------------------------
