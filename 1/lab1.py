a = -214783647
b = -32767
c = 214483
d = 0
e = 214783647

print()
# Breaking down the expression into intermediate steps
step1 = e - b
print(f"1) e-b = {step1}")

step2 = a * (e - b)
print(f"2) a*(e-b) = {step2}")

step3 = e + d
print(f"3) e+d = {step3}")

step4 = c // (e + d)
print(f"4) c//(e+d) = {step4}")

step5 = a * (e - b) * (c // (e + d))
print(f"5) a*(e-b)*(c//(e+d)) = {step5}")

step6 = d + b
print(f"6) d+b = {step6}")

step7 = (d + b) // e
print(f"7) (d+b)//e = {step7}")

res = a * (e - b) * (c // (e + d)) - ((d + b) // e)
print(f"8) a*(e-b)*(c//(e+d))-((d+b)//e) = {res}")
