use warnings;
use strict;
use File::Copy;
use List
#git log --oneline --all | wc -l
my $dir1 = $ARGV[0]; #dir1 is the main folder
my $dir2 = $ARGV[1]; #dir2 is to copy folder
print STDOUT "Running easy_git_push on $dir1 and $dir2...\n";

opendir( DIR, $dir1 ) or die "can't opendir $dir1: $!";
my $file;
my @filelist1;
while ( defined( $file = readdir(DIR) ) ) {
	next if $file =~ /^\.\.?$/;                # skip . and ..
	push( @filelist1, $file );              #read in all files from directory
	#print("$file\n");
}
closedir(DIR);

opendir(DIR, $dir2) or die "can't opendir $dir2: $!";
my @filelist2;
while ( defined( $file = readdir(DIR) ) ) {
	next if $file =~ /^\.\.?$/;                # skip . and ..
	if ( $file =~ m/gsea_report_for/ ) {
		push( @filelist2, $file );              #read in all files from directory
		#print("$file\n");
	}
}
closedir(DIR);



sub compare_two_file_versions
{
	my $file1 = shift;
	my $file2 = shift;

	open(INPUT, "$file1") or die "can't open $file1: $!";
	my $header = <INPUT>;
	my $version = s/\"local \=/
	close(INPUT);


}

