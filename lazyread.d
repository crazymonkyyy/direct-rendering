#!/usr/bin/env -S sh -c 'dmd -run "$0" "$1" "$2" "$3" | ffmpeg -f rawvideo -pixel_format rgb24 -video_size 1920x1080 -i pipe: -i $2 -preset ultrafast $(basename "$1" .d).mp4'
//$0 this file
//$1 the text file
//$2 mp3
//$3 image
import std;

enum chunk=(1920*3)/2;
enum fps=25;
void main(string[] input){
	//handle input
	string textfile=input[1];
	string mp3file=input[2];
	string imagefile=input[3];
	
	//text image
	executeShell("rm temp.png");
	executeShell(
		"convert -size 960x -font Helvetica -pointsize 32 caption:@"
		~textfile~" -fill black temp.png"
		);
	ubyte[] text=cast(ubyte[])executeShell("convert temp.png rgb:-").output;
	ubyte[chunk] blankline=255;
	ulong textlength=text.length/chunk;
	//assert(textlength==1794,textlength.to!string);
	//assert(text.length>chunk,cast(string)text);
	
	//mp3 handling
	string mp3timestring=executeShell(
		"ffmpeg -v quiet -stats -i "~mp3file~" -f null -"
	).output;
	{//clean up "carriage return"
		ulong sad;
		foreach(i,c;mp3timestring){
				if(cast(ubyte)c==13){
					sad=i;
				}
			}
		mp3timestring=mp3timestring[sad+1..$];
	}
	//size=N/A time=00:04:44.68 bitrate=N/A speed=1.39e+03x
	//0123456789012345678901234567890
	int mp3time;
	try{
		mp3time=mp3timestring[14..16].to!int*(60*60)*fps;
		mp3time+=mp3timestring[17..19].to!int*60*fps;
		mp3time+=mp3timestring[20..25].to!float*fps;
	} catch(Throwable){
		assert(0,cast(string)mp3timestring~"...."~mp3timestring[0..25]);
	}
	//mp3time=7117;
	
	//image
	assert(executeShell("convert "~imagefile~" -format %wx%h info:").output=="960x1080");
	ubyte[] image=cast(ubyte[])executeShell("convert "~imagefile~" rgb:-").output;
	
	//final prep
	void write(ubyte[] a){
		stdout.rawWrite(a);
	}
	//int mp3time=1000;
	enum offset=1080/2;
	foreach(frame;0..mp3time){
		foreach(y;0..1080){
			//write(text[chunk*frame..chunk*(frame+1)]);
			write(image[chunk*y..chunk*(y+1)]);
			//y+=(frame*textlength)/mp3time;
			y+=(float(frame)/mp3time)*(textlength);
			y-=offset;
			if(y<0 || y>=textlength){
				write(blankline[]);
			} else {
				write(text[chunk*y..chunk*(y+1)]);
			}
	}}
}