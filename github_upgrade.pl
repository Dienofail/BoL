use warnings;
use strict;
use Tie::File;
use Cwd; 

my $dir = getcwd();
my $new_host = 'raw.github.com';
opendir( DIR, $dir ) or die "can't opendir $dir: $!";
my $file;
my @filelist;
while ( defined( $file = readdir(DIR) ) ) {
	next if $file =~ /^\.\.?$/;                # skip . and ..
	next if $file =~ /tags/;
	if ( $file =~ m/.lua/ ) {
		push( @filelist, $file );              #read in all files from directory
		print("$file being added to examine list\n");
	}
}
closedir(DIR);


for my $i (0..$#filelist)
{
	edit_file($filelist[$i]);
}
# local UPDATE_NAME = "Sivir"
# local UPDATE_HOST = "bitbucket.org"
# local UPDATE_PATH = "/dienofail/bol/raw/master/Sivir.lua".."?rand="..math.random(1,10000)
# local AUTOUPDATE = true
# local UPDATE_HOST = "raw.github.com"
# local UPDATE_PATH = "/honda7/BoL/master/Common/VPrediction.lua".."?rand="..math.random(1,10000)
sub edit_file 
{
	my @array;
	my $input = shift;
	tie @array, 'Tie::File', $input or die $!;
	for my $i (0..$#array)
	{
		if ($array[$i] =~ m/local version = "(.*)"/)
		{
			my $current_version = $1; 
			my $new_version = $current_version + 0.01;
			$array[$i] = "local version = \"$new_version\"";
			print STDOUT "Upgrading $input from $current_version to $new_version\n";
		}

		if ($array[$i] =~ m/local UPDATE_HOST/)
		{
			my $old_update_host = $array[$i];
			$array[$i] = "local UPDATE_HOST = \"raw.github.com\"";
			print STDOUT "Upgrading $input from $old_update_host to $array[$i]\n";
		} 

		if ($array[$i] =~ m/local UPDATE_PATH/)
		{
			my $old_update_path = $array[$i];
			$array[$i] =~ s/dienofail/Dienofail/g;
			$array[$i] =~ s/\/raw//g;
			$array[$i] =~ s/bol/BoL/g;
			print STDOUT "Upgrading $input from $old_update_path to $array[$i]\n";
		}
	}
	untie @array;
}