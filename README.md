#How to develop a data-analysis watchdog:
#R + Python + Bash

##Author: Tamer Soliman

Since your Time and attention are limited resources, you may want to automate some of the data wrangling/modeling routines that have proven stable via thorough examination. This will insure efficiency and accuracy of your workflow , while freeing up your mental resources to handle more novel analyses.

In this tutorial , I walk you through the steps for developing an analysis watch dog  on a Linux machine. You'll end up with an R script lurking patiently at the background of your box. When data files show up, the script is auto-triggered to action. It crunches the data and writes the output to your database. it then emails you a note of its success/failure , and goes back lurking for the next batch of data. Best of all, this data grinding goes quietly in the background without disturbing any of your foreground jobs.

Deployment of this data-triggered analytic routine will require writing 5 scripts/modules: 
*    The first is an R script specifying how your data will be processed. 
*    The second is a Bash script that will write the R output to a database.
*    Third is a Python script that will shoot you an email note at the end of each round of data crunching.
*    The fourth is a mastermind Bash script that will orchestrate the relation between the former 3 and the triggering script.
*    Finally, the fifth is a script specifying the event that will trigger the whole system to action.

This modular design is meant to help you pick and choose what best fits your needs, without necessarily committing to the whole system. All 5 scripts can be downloaded/cloaned at this repository: [Automated-Data-Crunching](https://github.com/TamerSoliman/Automated_Data_Crunching). Let us explore how to develop each of these scripts here:

(P.S. There are ways to build an equivalent system on Windows and exclusively with Python; email me and I'll post a modified version of this tutorial)

##The setup:

*    Ubunto 14.04, running:
*    Upstart  1.12.1
*    csvkit 0.9.1
*    R 3.1.1
*    PostgreSQL server 9.3
*    Python 3.4, running Yagmail 0.5.14

##Script 1: descriptives.R

This is the principle script that will conduct your desired analyses. The content of this R script will obviously depend on the nature of your data and application. Here I illustrate a wrangling job that is neither overly simplistic nor overly complex.  The script will import data from multiple csv's, extract some descriptive statistics, then spit out a CSV tabulating these descriptives.

Let's assume that you are an [UX](http://www.uxbooth.com/articles/complete-beginners-guide-to-design-research/) researcher.  You are running a study to evaluate the renovations you introduced to the design of your client's website. You posted 2 web-based surveys, each comprising 20 questions. When a new participant/informant opts in for the experiment, they are randomly assigned to exploring either the new or old version of the website. Either way, the participant takes the two surveys, once before and once after interacting with the website. 

You'll ultimate goal is to gauge the change in the responses of survey_a and survey_b  as a function of the new/old website experience.  For our current purposes, however, it is sufficient to crunch some descriptive statistics. 

So, when a participant is run through the experiment, you end up with two csv's. One will list responses to survey_a and survey_b before the website experience, and another lists responses to the same surveys after the experience (i.e., 2 columns per file). 
The two csv's listed below are for Participant 1  (who happens to have been assigned to the *new* website group):

*    P001_new_before.csv
*    p001_new_after.csv

Your R script will be triggered to action once these 2 files are created (explained later in detail). It will import data from the first file. For each of the 2 survey columns, the mean, standard deviation, and frequency of response 5 ("*extremely agree*") and response 0 ("*extremely disagree*") will be computed. Then, the same will be done for the second file. Finally, a dataframe with the descriptives will be generated and written to a new csv file (see layout below). Here is the annotated code:

```

#!/usr/bin/env Rscript
#names of csv's in current directory put  in a character vector
files <- list.files(".", pattern=".csv$")
# import data from csv's, one file at a time
for (file in 1:length(files)) {
	df<-read.csv(files[file])

	# compute 4 descriptives per survey column
	av_a <- mean(df$survey_a, na.rm=TRUE)
	av_b <- mean(df$survey_b, na.rm=TRUE)
	sd_a <- sd(df$survey_a, na.rm=TRUE)
	sd_b <- sd(df$survey_b, na.rm=TRUE)
	freq5_a <-sum(ifelse(df$survey_a == 5, 1,0))
	freq5_b <-sum(ifelse(df$survey_b == 5, 1,0))
	freq0_a <-sum(ifelse(df$survey_a == 0, 1,0))
	freq0_b <-sum(ifelse(df$survey_b == 0, 1,0))
	#store descriptives in temporary df
	#The df follows long format
	#First 3 variables are string cutouts from csv file name
	temp<-data.frame(
	id = c(substr(files[file],1,4)),
	group = c(substr(files[file], 6,8)),
	when  = c(substr(files[file],10,12)),
	survey = c("a", "b"),
	avg = c(av_a, av_b),
	spread = c(sd_a, sd_b),
	freq5 = c(freq5_a, freq5_b),
	freq0 = c(freq0_a, freq0_b)
	)

	#DF "temp" gets new name per iteration to prevent overwriting
	name<-paste("output",file,sep="")
	assign(name,temp)
}
#binding descriptives of 2 input files into 1 output csv 
 output<-rbind(output1,output2)
write.csv(output,"./output.csv", row.names=FALSE)

```

You can save the above script in the same directory where the input and output csv's are created. I am also assuming that there are no other csv files in that directory.

But what happens to the derived data  in the output file? 
Well, you can further process it whichever way you want. In this tutorial, I show you how to upload its content to a database. Specifically, data will be appended to an existing table on a database served on the current platform. This way, you can automatically stack data for all participants in one convenient table until the time for inferential statistics comes.

##Script2: DB_Storing.sh

Here I assume that you have a postgresql database server on the current Ubunto machine, and that you start the server only when data transactions are necessary (to save resources). I also assume that you had already initialized a table, called "situx", with necessary column definitions , and that the table resides in a database called "experiment." Finally, I also assume that the current (unprivileged) Linux username has permissions to access DB "experiment."

Below I take advantage of a brilliant tool from the "CSVKit" package called [*CSVSQL*](http://csvkit.readthedocs.io/en/0.9.1/scripts/csvsql.html). This utility function main streams the uploading of data from a csv to a new/old database table.

The code below can be saved in the same directory as above

```

#!/usr/bin/env bash
#get the database server started
sudo service postgresql start
# append "output.csv" content to table "situx" in db "experiment"
# it's 1 long command split over 2 lines
csvsql --db postgresql:///experiment \
--no-create --table situx --insert < ./output.csv
#close the database server
sudo service postgresql stop

```

##Script 3: send_email.py

When data from a new participant successfully make it through the above 2 steps, you certainly want to be notified! Notifications become even more important if one or both of the above steps fail.

Python has a convenience module, [*yagmail*](https://github.com/kootenpv/yagmail), that makes it easy to send automated email notifications from your Gmail account. However, before you can use it, you need to allow less secure apps access to your account. This can be done [here](https://www.google.com/settings/security/lesssecureapps).

The body of the email you'll receive will always list the names of the files that had just been processed. You'll receive one of 3 subject lines, however, depending on whether the two steps of data crunching and storing succeeded or (partly) failed.

How does the script select the message you'll receive?
Well, the python script will receive two variables from the Bash  environment. The first will encode the value 0 if the R script had been executed without errors, while the second does the same for the db-storing script (these will be explicitly coded as we rite *Script 4*, below). Python will rely on these variables to  choose the subject-line message.

Customize the code below by providing your sender gmail account credentials (*username* and *password*) as well as the recipient email address (which can be the same as the sender). Save the script in the same directory as above.

```

#!/usr/bin/env python3
import sys
import glob
import yagmail
#collect names of csv's in current dir 
files = glob.glob("*.csv")
#list file names in body of email
#its 1 long command split on 2 lines 
body = "Here are the file names:{0}{1}".format(
"\n", "\n".join(files))
#catch exit code of R script in a var
descriptives = int(sys.argv[1])
#catch exit code of database storing in a var
storing=int(sys.argv[2])
#select email subject line based on exit codes
if descriptives == storing == 0:
	subj="Experiment4: Data for 1 more Participant!"
elif descriptives != 0:
	subj="Experiment 4: Computing Descriptives Failed!"
elif storing != 0:
	subj="Experiment 4: descriptives OK but storing failed!"
#sending email; provide your credentials
yag=yagmail.SMTP(
"USERNAME@gmail.com", 
"PASSWORD")
yag.send(
to="USERNAME@HOST.com", 
subject=subj, 
contents = body)
yag.close()

```

##Script 4: master.sh

Now to the  mastermind! This Bash script will orchestrate the information flow across the 3 above scripts, on the one hand, and the triggering script (Script 5, below), on the other.

When this script runs, it kick starts the R script and catches the exit code in a variable. It then runs the db_storing script, and catches its exit code  in a second variable. Next, it passes the two variables as arguments to the python script and runs it. 

Finally, the script cleans up by deleting the csv's. This is necessary for the next round of data analysis/storing to run accurately, as the tool is designed to run data for one participant at a time.  You can replace this clean-up step with code that archives the csvs (in my own projects, I upload the raw data to separate db tables before running the R script; see my [Automated_data_Transfer](https://github.com/TamerSoliman/Automated_Data_Transfer) and [Automated_Data_Storing](https://github.com/TamerSoliman/Automated_Data_Storing) repositories).

Also, the script deletes a dummy text file that is used as the trigger for the whole process ( later in detail). You can save the code for the script in the same directory as above.

```

#!/usr/bin/env bash
cd /home/vagrant/from_win/
./descriptives.R --vanilla --slave
descriptives=$?
./db_storing.sh
storing=$?
./send_email.py $descriptives $storing
#cleaning up by removing csv's 
if [ $descriptives -eq 0 ] && [ $storing -eq 0 ]
	then
	files=`ls *.csv`
	for file in $files
	do
	rm $file
	done
	#delete txt file that triggered current bash script
	rm ./success.txt
fi

```

##Script 5: kicker.conf

This is the core script that makes it possible to automate all of the above.  It is a configuration file for a Ubunto utility called [*Upstart*](http://upstart.ubuntu.com/cookbook/). *Upstart* makes it possible to schedule  event-driven jobs on Linux machines. These short- or long-term jobs are kick-started at the background  of your machine when Upstart detects your prespecified trigger event.  And, if your desired job does not stop on its own, you can optionally configure Upstart to stop it on a another event.

In our case, Upstart is configured to run the master Bash script, "master.sh", when data files become available. Although data arrive in csv files, I chose to specify the creation of a dummy text file, *success.txt*, as the triggering event for our data-crunching mill. The idea here is that the data-generation mechanism would first complete generating all necessary CSV's, then --and only then--  throws in a dummy file for the sole purpose of triggering Upstart.  This has proven the most stable and convenient strategy in most of my projects. On the one hand, it is easy to configure the data collection mechanism to "touch" a dummy text file (see [Automated-Data-Transfer](https://github.com/)) after it had completed generating substantive files. On the other, asking upstart to initialize your job upon file creation is one of the easiest ways to configure Upstart (and, trust me, Upstart can get really complicated!).

Note that the dummy file, *success.txt*, will be deleted, alongside the csv files, once the master Bash script gets the job done. 

Save the code below in "/etc/init/"

```

#Specify trigger event as creation of dummy file
start on file FILE=/home/USER/DIRECTORY/success.txt EVENT=create
# provide your unprivileged user name
setuid USERNAME
#create log file
console log
#move focus to the directory of scripts & csv's
chdir /home/USER/DIRECTORY/
#finally, run the master bash script
task
	exec /home/USER/DIRECTORY/master.sh  


```

##Testing and Debugging:

Great! You now should have a data-analysis watchdog that will crunch your data once they show up!

Check if "kicker.conf" is up and running:

```

Sudo service kicker status

```

If the service is down, you can start it:

```

sudo service kicker start

```

To test the whole system, 

```

cd /home/user/directory
touch success.txt

```

Check out the recipient inbox address you specified in "send_email.py." You should see an email with a subject-line message  notifying you of the failure of computing descriptives (there were no data files).
Delete the text file, add two data files, then retest the system by "touching" another "success.txt." You should now receive a success note in 
the same inbox.  Go start the Postgresql server and check the table for the data.

If you don't receive any email, or if you don't find the data in the database, you can check the log file  "*/var/log/upstart/kicker.log*" for error messages:

```

tail -f /var/log/upstart/kicker.log

```

Finally, let me remind you that all above scripts can be found here: 
[Automated_Data_crunching](https://github.com/TamerSoliman/Automated_Data_Crunching)

Enjoy!
	#Whom Should You Blame?

Well, No one but yourself! I offer no warrantee, implied or explicit, for the code in any of my repositories. Use it at your own risk and discretion. I accept no liability, whatsoever, as a result of using it, or using a modified version of it!

Tamer Soliman, the author of this repository, has been immersed in data collection and statistical modeling since 2002. He holds a PhD in quantitative Experimental Psychology, where he designs experiments to understand and model human cognition, decision making, socio-cultural behavior, attitudes, and actions. He develops data-centered utilities and applications that subserve his data-science and machine-learning projects. While he approaches his projects with the mindset of a skeptic homo-academicus,  he understands the concept of "deadlines", and loves making money just as all other homo-sapiens!