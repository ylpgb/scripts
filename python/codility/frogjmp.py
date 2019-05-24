def solution(X, Y, D):
    if((Y-X)%D):
        return ((Y-X)//D + 1)
    else:
        return ((Y-X)//D)

x=10
y=85
d=30
print("answer is {}".format(solution(x,y,d)))