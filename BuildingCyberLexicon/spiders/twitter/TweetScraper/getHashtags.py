import json

def getMentionsAndHashtags():
    with open("../../../outputfiles/cwn.json", "r+") as ff:
        data = ff.read()
        hashtagsMentions, data =[], json.loads(data)
        for dd in data:
            try:
                text = dd.get('text')
                for i in text.split():
                    if (i.startswith('#') or i.startswith('@')) and (len(i)>3 and len(i)<15):
                        hashtagsMentions.append(i)
            except:
                pass
        return hashtagsMentions




if __name__ == "__main__":
    mtags=getMentionsAndHashtags()
    mtags = [i.strip().lower() for i in mtags]
    mtags=sorted(list(set(mtags)))
    with open("../../../inputfiles/mentionsAndHashtags.txt", "w+") as ff:
        for tag in mtags:
            ff.write(tag+"\n")
        ff.close()
