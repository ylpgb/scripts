
def solution(A, X):
    fence_count = {}
    for fence in A:
        fence_count[fence] = fence_count.get(fence, 0) + 1
    num_of_pens = 0
    usable_fences = []
    for fence in fence_count:
        if fence_count[fence] < 2:
            # Less than one pair. We cannot use it.
            continue
        elif fence_count[fence] < 4:
            usable_fences.append(fence)
        else:
            usable_fences.append(fence)
            # We consider the square pen here.
            if fence * fence >= X:
                num_of_pens += 1
    # We consider the non-square pen here.
    usable_fences.sort()
    candidate_size = len(usable_fences)
    for i in range(candidate_size):
        # Use binary search to find the first fence pair, that
        # could be used with current pair to form a pen.
        begin = i + 1
        end = candidate_size - 1
        while begin <= end:
            mid = (begin + end) // 2
            if usable_fences[mid] * usable_fences[i] >= X:
                end = mid - 1
            else:
                begin = mid + 1
        # Now the usable_fences[end + 1] is the first qualified
        # fence.
        combination_num = candidate_size - (end + 1)
        num_of_pens += combination_num
        if num_of_pens > 1000000000:
            return -1
    return num_of_pens       
    
a=[1,2,5,1,1,2,3,5,1]
x=5
print("answer is {}".format(solution(a,x)))