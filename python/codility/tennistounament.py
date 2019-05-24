def solution(P, C):
    pairs = P//2
    return(min(pairs, C))

    
p=10
c=3
print("answer is {}".format(solution(p,c)))