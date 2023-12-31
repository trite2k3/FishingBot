#!/bin/bash

#Time to focus window
echo "Sleeping 3s."
sleep 3

function drawselect
{
    #Run the binary
    drawselect=$(./drawselect)

    #We need some sort or error check for sanity
    if [ "$drawselect" = "couldn't grab pointer:" ]
        then
        return 1
    elif [ "$drawselect" = "couldn't grab keyboard:" ]
        then
        return 1
    fi

    #Split the output into four variables
    IFS=',' read -ra values <<< "$(echo "$drawselect")"

    #Assign
    varW="${values[0]}"
    varH="${values[1]}"
    varX="${values[2]}"
    varY="${values[3]}"

    echo "Coordinates grabbed." $varW $varH $varX $varY
    return 0
}

function limitedsearch
{
    #Run the binary
    #limitedearch=$(./limitedsearch $1 $2 $3 76 $CDelta $4 $5 1 1)
    limitedearch=$(./limitedsearch $1 $2 $3 $ColorDeltaLimited $CDelta $4 $5 1 1)
    echo "# Running: ./limitedsearch" $1 $2 $3 $ColorDelta $CDelta $4 $5 "1 1"

    #Only do stuff if pixel is found
    if [ "$limitedearch" = "No" ]
        then
            #echo "Pixel not found."
            return 1
        else
        #Split the output into two variables
        IFS=',' read -ra limitedvalues <<< "$(echo "$limitedearch")"

        #Assign
        varLimitedX="${limitedvalues[0]}"
        varLimitedY="${limitedvalues[1]}"
        varLimitedR="${limitedvalues[2]}"
        varLimitedG="${limitedvalues[3]}"
        varLimitedB="${limitedvalues[4]}"
        return 0
    fi
}

function widthsearch
{
    #Run the binary
    #Debug
    #pixelsearch=$(./searchwidth $1 $2 $3 $ColorDelta $CDelta $varX $varY $varW $varH > log.txt)
    echo "# Running: ./search $1 $2 $3 $ColorDelta $CDelta $varX $varY $varW $varH"
    pixelsearch=$(timeout 30 ./searchwidth $1 $2 $3 $ColorDelta $CDelta $varX $varY $varW $varH)

    #Only do stuff if pixel is found
    if [ "$pixelsearch" = "No" ]
        then
            #echo "Pixel not found."
            return 1
        else
        #Split the output into two variables
        IFS=',' read -ra pixelvalues <<< "$(echo "$pixelsearch")"

        #Assign
        FoundX="${pixelvalues[0]}"
        FoundY="${pixelvalues[1]}"
        return 0
    fi
}

function checkcurrentstatus
{
    #Can we see the float?
    # R, G, B
    #if widthsearch 31 14 10 #SW/Elwynn Forest
    if widthsearch 50 16 12 #WC
    then
        echo "# Float detected."
        floatdetected=1
    else
        echo "# Float not found."
    fi
}

function waitforbait
{
    while true
    do
        if limitedsearch 31 14 10 $FoundX $FoundY
        then
            echo "# Float still there."
        else
            echo "# Bait!"
            echo "X: "$varLimitedX", Y: "$varLimitedY", R: "$varLimitedR", G: "$varLimitedG", B: "$varLimitedB
            xdotool mousemove $FoundX $FoundY
            sleep .$[ ( $RANDOM % 20 ) + 1 ]s
            xdotool mousedown 3
            sleep .$[ ( $RANDOM % 20 ) + 0 ]s
            xdotool mouseup 3
            sleep .$[ ( $RANDOM % 50 ) + 0 ]s
            xdotool mousedown 3
            sleep .$[ ( $RANDOM % 30 ) + 0 ]s
            xdotool mouseup 3
            floatdetected=0
            baittick=0
            break
        fi

        if [ $baittick -gt 160 ]
        then
            echo "# Waited too long for bait. Starting over."
            baittick=0
            break
        fi

        ((baittick++))
        sleep 0.15
    done
}

#Global pixelsearch arguments
#Variance allowed in color
#CD5 and CDL 75 for Elwynn forest pool with 31 14 10 RGB.
ColorDelta=5
ColorDeltaLimited=75
CDelta=1

#Instance status boolean
fishtick=0
baittick=0
floatdetected=0

#Establish scan area
echo "Draw a rectangle on your fishing-area."
drawselect
sleep 0.5

#
# Check drawn rectangle debug
# for i in $(cat log.txt); do IFS=',' read -ra values <<< "$(echo "$i")"; xdotool mousemove "${values[0]}" "${values[1]}" ;done

while true
do
    #Start fishing
    echo "Casting rod."
    xdotool mousemove $varX $varY
    xdotool key ctrl+d
    sleep 0.5

    echo "###"
    #Start pixelsearching the window for POI
    checkcurrentstatus

    if [ $floatdetected = 1 ]
    then
        echo "Moving mouse to " $FoundX $FoundY
        xdotool mousemove $FoundX $FoundY
        waitforbait
    fi

    ((fishtick++))
    sleep 5
    echo "###" $fishtick
done
