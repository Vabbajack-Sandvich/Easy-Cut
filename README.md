# Easy Cut


This version is not intended to be a fork of Bookmark Moments, I used their code as a base and changed it.


=================================


This converts VLC into a video editor by generating ffmpeg commands for batch files based on the time cuts that were made in the list. This makes it generate ffmpeg commands using the time you paused the video at and clicked the cut button.


# Example:


ffmpeg -y -ss 00:00:00 -to 00:20:00 -i 2025-02-28_19-23-21.mp4 -c:v libx264 -crf 20 -preset ultrafast -r 60 2025-02-28_19-23-21_uf_t_1_1x.mp4


It exports them to the memos.txt file in the appdata VLC folder.


It automatically generates: new output filenames with what cut revision and what speed, it keeps track of where the time left off between commands, it also generates an end command that automatically fills in from where you made your last cut to the very end of the file length.



