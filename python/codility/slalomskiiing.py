def LongestIncreasingSubsequence(seq):
    ''' The classic dynamic programming solution for longest increasing
        subsequence. More details could be found:
        https://en.wikipedia.org/wiki/Longest_increasing_subsequence
        http://www.geeksforgeeks.org/dynamic-programming-set-3-longest-increasing-subsequence/
        http://stackoverflow.com/questions/3992697/longest-increasing-subsequence
    '''
    print(seq)
    # smallest_end_value[i] = j means, for all i-length increasing
    # subsequence, the minmum value of their last elements is j.
    smallest_end_value = [None] * (len(seq) + 1)
    # The first element (with index 0) is a filler and never used.
    smallest_end_value[0] = -1
    # The length of the longest increasing subsequence.
    lic_length = 0
    for i in range(len(seq)):
        # Binary search: we want the index j such that:
        #     smallest_end_value[j-1] < seq[i]
        #     AND
        #     (  smallest_end_value[j] > seq[i]
        #        OR
        #        smallest_end_value[j] == None
        #     )
        # Here, the result "lower" is the index j.
        lower = 0
        upper = lic_length
        while lower <= upper:
            mid = (upper + lower) // 2
            if seq[i] < smallest_end_value[mid]:
                upper = mid - 1
            elif seq[i] > smallest_end_value[mid]:
                lower = mid + 1
            else:
                raise "Should never happen: " + \
                      "the elements of A are all distinct"
        if smallest_end_value[lower] == None:
            smallest_end_value[lower] = seq[i]
            lic_length += 1
        else:
            smallest_end_value[lower] = \
                min(smallest_end_value[lower], seq[i])
    return lic_length
def solution(A):
    # We are solving this question by creating two mirrors.
    bound = max(A) + 1
    multiverse = []
    for point in A:
        # The point in the double-mirror universe.
        multiverse.append(bound * 2 + point)
        # The point in the mirror universe.
        multiverse.append(bound * 2 - point)
        # The point in the original universe.
        multiverse.append(point)
    return LongestIncreasingSubsequence(multiverse)
    
a=[15,13,5,7,4,10,12,8,2,11,6,9,3]
print("answer is {}".format(solution(a)))