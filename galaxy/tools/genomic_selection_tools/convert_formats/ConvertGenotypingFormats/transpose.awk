#!/usr/bin/gawk -f

BEGIN {
    max_x =0;
    max_y =0;
}

{
    max_y++;
    for( i=1; i<=NF; i++ )
    {
        if (i>max_x) max_x=i;
        A[i,max_y] = $i;
    }
}

END {
    for ( x=1; x<=max_x; x++ )
    {
        for ( y=1; y<=max_y; y++ )
        {
            if ( (x,y) in A ) printf "%s",A[x,y];
            if ( y!=max_y ) printf " ";
        }
        printf "\n";
    }
}
