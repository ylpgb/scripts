def solution(A):
    maxH = 0
    minH = 0
    maxD = 0
    for a in A:
        if a > maxH:
            d = maxH - minH
            maxH = a
            minH = a
        elif a < minH:
            minH = a
        else:
            d = a - minH
            
        print("maxH: {} minH: {} d: {} maxD: {}".format(maxH, minH, d, maxD))
        if d > maxD:
            maxD = d
    return maxD

    
a=[1,3,2,1,2,1,5,3,3,4,2]
print("answer is {}".format(solution(a)))