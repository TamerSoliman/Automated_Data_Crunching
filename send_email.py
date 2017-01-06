#!/usr/bin/env python3
import sys
import glob
import yagmail
files = glob.glob("*.csv")
body = "Here are the file names:{0}{1}".format("\n", "\n".join(files))
descriptives = int(sys.argv[1])
storing=int(sys.argv[2])
if descriptives == storing == 0:
        subj="Experiment4: Data for 1 more Participant!"
elif descriptives != 0:
        subj="Experiment 4: Computing Descriptives Failed!"
elif storing != 0:
        subj="Experiment 4: descriptives OK but storing failed!"

yag=yagmail.SMTP("USERNAME@gmail.com", "PASSWORD")
yag.send(to="USER@HOST.com", subject=subj, contents = body)
yag.close()

vagrant@data-science-toolbox:~/from_win$




























cat send_email.py
#!/usr/bin/env python3
import sys
import glob
import yagmail
files = glob.glob("*.csv")
body = "Here are the file names:{0}{1}".format("\n", "\n".join(files))
descriptives = int(sys.argv[1])
storing=int(sys.argv[2])
if descriptives == storing == 0:
        subj="Experiment4: Data for 1 more Participant!"
elif descriptives != 0:
        subj="Experiment 4: Computing Descriptives Failed!"
elif storing != 0:
        subj="Experiment 4: descriptives OK but storing failed!"

yag=yagmail.SMTP("tamerpsych@gmail.com", "psychtamer")
yag.send(to="tamer.soliman@asu.edu", subject=subj, contents = body)
yag.close()

vagrant@data-science-toolbox:~/from_win$




























