def solution(A):
    mark=[0] * len(A)
    for idx in range(len(A)-1):
        found = 0
        if(mark[idx]==0):
            for idy in range(idx+1, len(A)):
                if(A[idx] == A[idy]):
                    found = 1
                    mark[idx]=1
                    mark[idy]=1
                    break;
    for idx in range(len(A)):
        if(mark[idx]==0):
            return A[idx]

a=[9,3,9,3,9,1,9]
print("answer is {}".format(solution(a)))