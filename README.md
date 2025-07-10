# Easy Cut Extention For VLC For Generating FFMPEG Cut Commands


1.1 update - I changed 1x cuts over to -c copy because it's faster.


The way it makes the cuts is by leaving the original file alone, but generating new files at the specified times.


This allows for easy editing by deleting the unwanted sections after splitting the video and then concatenating them.


All without having to open a project editor of some kind, save a new project directory, fight filters, fight effects, or do anything else GUI-related.


This just simply cuts the video into new files with a batch file you generated with a few button clicks and pausing the player cursor where you want a cut.


This version is not intended to be a fork of Bookmark Moments, I used their code as a base and changed it.


This is a work in progress and more of a hack than an actual attempt at a final product.


The majority of the stuff is still in the extension, just either ignored, skipped or commented out.


But.


It does work and makes it easy to cut up videos.


=================================


This converts VLC into a video editor by generating ffmpeg commands for batch files based on the time cuts that were made in the list. This generates ffmpeg commands using the time you pause the video and click the cut button.


# Note:


This assumes you have ffmpeg installed and in the system path variables.


Don't use file names that have spaces.


# Example:


This uses the time codes for the stored cuts to generate these commands.


This is a normal 1X speed cut command.


ffmpeg -y -ss 00:00:00 -to 00:20:00 -i 2025-02-28_19-23-21.mp4 -c copy 2025-02-28_19-23-21_uf_t_1_1x.mp4


This is a 2X speed cut command. This keeps the pitch on the audio normal and not high pitched while speeding up the video.


ffmpeg -y -ss 00:00:00 -to 00:00:00 -i 2025-02-28_19-23-21.mp4 -c:v libx264 -crf 20 -preset ultrafast -r 60 -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" -map "[v]" -map "[a]" 2025-02-28_19-23-21_uf_t_3_2x.mp4


The 2X 4X 8X all do the same thing, just at different speeds.


It automatically generates: new output filenames with what cut revision and what speed, it keeps track of where the time left off between commands, it also generates an end command that automatically fills in from where you made your last cut to the very end of the file length.


It exports them to the memos.txt file in the appdata VLC folder when you click the Export Cuts button.


From there you can copy and paste the commands into a batch file in the same directory as your mp4 files and run it to make the cuts.



