NR==FNR{
    imagesets[$0] = 1;
}
NR>FNR{
    imagenames[$0] = 1;
}
END{
    for (name in imagenames) {
        if (imagesets[name] == 0) {
            print name, "not exist";
        }
    }
    for (set in imagesets) {
	if (set ~ /[0-9]/) {
            continue;
        }
        if (imagenames[set] == 0) {
            print set, "unnecessary";
        }
    }
}
