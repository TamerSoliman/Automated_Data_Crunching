
#!/usr/bin/env Rscript
files <- list.files(".", pattern=".csv$")
for (file in 1:length(files)) {
	df<-read.csv(files[file])
	av_a <- mean(df$survey_a, na.rm=TRUE)
	av_b <- mean(df$survey_b, na.rm=TRUE)
	sd_a <- sd(df$survey_a, na.rm=TRUE)
	sd_b <- sd(df$survey_b, na.rm=TRUE)
	freq5_a <-sum(ifelse(df$survey_a == 5, 1,0))
	freq5_b <-sum(ifelse(df$survey_b == 5, 1,0))
	freq0_a <-sum(ifelse(df$survey_a == 0, 1,0))
	freq0_b <-sum(ifelse(df$survey_b == 0, 1,0))
	
	temp<-data.frame(
	id = c(substr(files[file],1,4)),
	group = c(substr(files[file], 6,8)),
	time = c(substr(files[file],10,12)),
	survey = c("a", "b"),
	avg = c(av_a, av_b),
	dev = c(sd_a, sd_b),
	freq5 = c(freq5_a, freq5_b),
	freq0 = c(freq0_a, freq0_b)
	)
	
	name<-paste("output",file,sep="")
	assign(name,temp)
}
output<-rbind(output1,output2)
write.csv(output,"./output.csv", row.names=FALSE)
