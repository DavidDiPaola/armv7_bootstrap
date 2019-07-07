if [ ! -f "$(which ffmpeg)" ]; then
	echo 'please install ffmpeg' 2>&1
	exit 1
fi
if [ ! -f "$(which xxd)" ]; then
	echo 'please install xxd' 2>&1
	exit 1
fi

ARG_INPUT="$1"
ARG_OUTPUT="$2"
if [ -z "$ARG_INPUT" ] || [ -z "$ARG_OUTPUT" ]; then
	echo "syntax: $(basename $0) <input file> <output file>" 2>&1
	exit 2
fi

ffmpeg -v quiet -i "$ARG_INPUT" -c:a pcm_s16le -ac 1 -ar 48000 -f s16le - | xxd -i - "$ARG_OUTPUT"
sed -i '1iunsigned char sample[] = {' "$ARG_OUTPUT"
echo '};' >> "$ARG_OUTPUT"

