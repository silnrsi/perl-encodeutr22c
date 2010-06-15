package Encode::Tec;

use IO::File;
use Compress::Zlib;

sub open
{
    my ($class, $fname) = @_;
    my ($res) = { fname => $fname };
    bless $res, ref $class || $class;

    my ($fh) = IO::File->new("<:raw", $fname) || die "Can't open $fname for reading";
    $/ = '';
    my ($dat) = <$fh>;
    $fh->close();
    my ($type) = unpack('a4', $dat);

    if ($type eq 'zQmp')
    {
        my ($inf, $status) = inflateInit();
        $dat = $inf->inflate(substr($dat, 12));
        $type = unpack('a4', $dat);
    }
    if ($type eq 'qMap')
    {
        my ($version, $hlen, $flagl, $flagr, $nname, $nft, $nrt) = unpack('N7', substr($dat, 4));
        my (@onames) = unpack("N$nname", substr($dat, 24));
        my (@oft) = unpack("N$nft", substr($dat, 24 + 4 * $nname));
        my (@ort) = unpack("N$nrt", substr($dat, 24 + 4 * $nname + 4 * $nft));

        $res->{'Version'} = $version;
        $res->{'lhs_flags'} = $flagl;
        $res->{'rhs_flags'} = $flagr;

        for ($i = 0; $i < $nname; $i++)
        {
            my ($id, $lname) = unpack('n2', substr($dat, $onames[$i]));
            $res->{'Names'}[$id] = unpack('a$lname', substr($dat, $onames[$i] + 4));
        }

        for ($i = 0; $i < $nft; $i++)
        {
            my ($t, $v, $l) = unpack('N3', substr($dat, $oft[$i]));
            $res->{'f_tables'}[$i] = substr($dat, $oft[$i], $l);
        }

        for ($i = 0; $i < $nrt; $i++)
        {
            my ($t, $v, $l) = unpack('N3', substr($dat, $ort[$i]));
            $res->{'r_tables'}[$i] = substr($dat, $ort[$i], $l);
        }
    }
    return $res;
}

1;

