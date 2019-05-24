def solution(A):
    histogram={}
    found = 0
    dominator = 0
    for element in A:
        histogram[element] = histogram.get(element, 0) + 1
    
    for element, count in histogram.items():
        if count > len(A)/2 :
            found = 1
            dominator = element
    
    if found==0 :
        return -1
    else:
        indices = []
        for idx in range(len(A)):
            if A[idx] == dominator:
                indices.append(idx)
        return indices
        

a=[3,4,3,2,3,-1,3,3]

print("answer is {}".format(solution(a)))