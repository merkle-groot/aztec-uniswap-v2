def sqrt_m(x):
    estimate = 0
    if x > 3:
        estimate = x//2 + 1
        previous_estimate = x
        while estimate < previous_estimate:
            previous_estimate = estimate
            estimate = (estimate + x//estimate) // 2

        estimate = previous_estimate
    elif x!= 0:
        estimate = 1

    return estimate

for i in range(0, 100):
    print("num: ", i, " , result: ", sqrt_m(i))

