def solution(N):
    s= str(bin(N)).strip("0b")
    
    max_gap=0
    current_gap=0
    for idx in range(len(s)):
        if(s[idx]=='0'):
            current_gap+=1
        if(s[idx]=='1'):
            if(max_gap<current_gap):
                max_gap = current_gap
            current_gap = 0                
    return max_gap

N=1041
print("Binary gap for {} is {}".format(N, solution(N)))