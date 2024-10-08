#!/bin/bash
#

set -e # Exit immediately if a command exits with a non-zero status.

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 --input-dir <input-dir> --rgb-dir-parent <rgb-dir-parent> [--verbose] --output-dir <output-dir>"
    exit 1
fi

# make a list of desk_with_person, sitting_xyz and walking_xyz
patternList=("walking_xyz" "sitting_xyz" "sitting_halfsphere" "walking_rpy" "walking_halfsphere")
patternList=("walking_xyz" "sitting_xyz" "walking_rpy" "walking_halfsphere")
patternList=("walking_halfsphere")

input_dir=""
verbose=false
output_dir=""
rgb_dir_parent=""
# parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --input-dir)
            input_dir="$2"
            shift # past argument
            shift # past argument
            ;;
        --rgb-dir-parent)
            rgb_dir_parent="$2"
            shift # past argument
            shift # past argument
            ;;
        -v|--verbose)
            verbose=true
            shift # past argument
            ;;
        -o|--output-dir)
            output_dir="$2"
            shift # past argument
            shift # past argument
            ;;
        *)
            echo "Unknown option: $1"
            shift
            # unknown option
            ;;
    esac
done

# make sure input_dir is not exists
if [ ! -d "$input_dir" ]; then
    echo "Input directory does not exist ($input_dir)"
    exit 1
fi

if [ ! -d "$rgb_dir_parent" ]; then
    echo "RGB parent directory does not exist ($rgb_dir_parent)"
    exit 1
fi

# output_dir empty, then error
if [ -z "$output_dir" ]; then
    echo "Output directory is empty"
    exit 1
fi

# make output_dir if it does not exist
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
fi

# make a function with name launch_mono_tum
launch_mono_tum() {
    num="$1"
    dir="$2"
    yamlFile=./Examples/Monocular/TUM${num}.yaml
    
    command="./cmake-build-release/bin/mono_tum ./Vocabulary/ORBvoc.txt $yamlFile $dir"
    if [ "$verbose" = true ]; then
        echo -e "\e[K running cmd: $command"
    fi

    # run the command 10 times and create output file for each run, outputfile will be named as basename of dir with {2d}.txt extension
    for i in {1..10}; do

        outputfileDir="./$output_dir/"
        mkdir -p "$outputfileDir"

        num2d=$(printf "%02d" "$i")
        outputfile=$(basename "$dir")_${num2d}

        # rgb_parent=$(basename "$dir")
        # rgb_parent=${rgb_parent%%_[0-9]*}
        # rgb_path="$rgb_dir_parent"/${rgb_parent}/rgb.txt
        # # make sure rgb_path contains the file
        # if [ ! -f "$rgb_path" ]; then
        #     echo "rgb_path does not exist: $rgb_path"
        #     exit 1
        # fi

        # # copy rgb.txt to the dir
        # cp "$rgb_path" "$dir"/rgb.txt

        # # remove all the line starting with '#' in rgb.txt
        # sed -i '/^#/ d' "$dir"/rgb.txt

        # # remove first line in rgb.txt
        # sed -i '1d' "$dir"/rgb.txt

        # override the saving to echo command each time
        # echo -e "\e[K $command"
        # $command

        # if KeyFrameTrajectory.txt is empty, then skip
        # if [ ! -s KeyFrameTrajectory.txt ]; then
        #    echo "KeyFrameTrajectory.txt is empty, skipping"
        #    continue
        # fi
        #
        # mv KeyFrameTrajectory.txt $outputfileDir/kf_$outputfile.txt
        #
        plotpath="$output_dir"/plot_${outputfile}
        resultpath="$output_dir"/path_${outputfile}

        # # copy groundtruth from rgb_parent to dir
        # cp "$rgb_dir_parent"/${rgb_parent}/groundtruth.txt "$dir"/groundtruth.txt

        # # remove all the line starting with '#' in groundtruth.txt
        # sed -i '/^#/ d' "$dir"/groundtruth.txt
        
        # # remove first line in groundtruth.txt
        # sed -i '1d' "$dir"/groundtruth.txt
        
        evo_file=$outputfileDir/evo_${outputfile}.txt

        evo_cmd="evo_ape tum $dir/groundtruth.txt $outputfileDir/kf_${outputfile}.txt -as --plot_mode xy --save_plot ${plotpath}_ape.pdf --save_results ${resultpath}_ape.zip --no_warnings --pose_relation trans_part"
        echo -e "\e[K $evo_cmd"
        $evo_cmd 2>&1 | tee $evo_file

        evo_cmd="evo_rpe tum $dir/groundtruth.txt $outputfileDir/kf_${outputfile}.txt -as --plot_mode xy --save_plot ${plotpath}_tr.pdf --save_results ${resultpath}_tr.zip --no_warnings --pose_relation trans_part"
        echo -e "\e[K $evo_cmd"
        $evo_cmd 2>&1 | tee -a $evo_file

        evo_cmd="evo_rpe tum $dir/groundtruth.txt $outputfileDir/kf_${outputfile}.txt -as --plot_mode xy --save_plot ${plotpath}_rr.pdf --save_results ${resultpath}_rr.zip --no_warnings --pose_relation rot_part"
        echo -e "\e[K $evo_cmd"
        $evo_cmd 2>&1 | tee -a $evo_file

    done
}

echo "Launching Monocular"
# iterate through all folders in input_dir, and see which is a superstring of the pattern
for pattern in "${patternList[@]}"; do
    for dir in "$input_dir"/*; do
        if [[ "$dir" == *"$pattern"* ]]; then
            # dir will have rgbd_dataset_freiberg{1d}_pattern_{2d}, extract 1d number
            num=$(echo "$dir" | grep -oP '(?<=rgbd_dataset_freiburg)\d(?=_'"$pattern"')')
            # eps_value if 2d number from previous comment
            # eps_value=$(echo "$dir" | grep -oP '(?<=_'"$pattern"_')\d+')
            eps_value=10
            # if num != 10 continue
            if [ "$eps_value" -ne "10" ]; then
                continue
            fi
            if [ "$verbose" = true ]; then
                echo -e "\e[K Launching $dir with Monocular, num: $num"
            fi
            cp /media/scratch/TUM/$(basename $dir)/rgb.txt $dir
            cp /media/scratch/TUM/$(basename $dir)/groundtruth.txt $dir
            launch_mono_tum "$num" "$dir"
        fi
    done
done
