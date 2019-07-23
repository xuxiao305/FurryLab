
fn inverseTest m =
(
    n11 = m[1][1]
    n12 = m[2][1]
    n13 = m[3][1] 
    n14 = m[4][1]
    n21 = m[1][2] 
    n22 = m[2][2] 
    n23 = m[3][2] 
    n24 = m[4][2]
    n31 = m[1][3] 
    n32 = m[2][3] 
    n33 = m[3][3] 
    n34 = m[4][3]
    n41 = 0
    n42 = 0
    n43 = 0
    n44 = 1.0

    t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44
    t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44
    t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44
    t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34

    det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14
    idet = 1.0 / det

    ret = #()
    append ret (Point4 0 0 0 0)
    append ret (Point4 0 0 0 0)
    append ret (Point4 0 0 0 0)
    append ret (Point4 0 0 0 0)


    ret[0+1][0+1] = t11 * idet
    ret[0+1][1+1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * idet
    ret[0+1][2+1] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44) * idet
    ret[0+1][3+1] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43) * idet

    ret[1+1][0+1] = t12 * idet
    ret[1+1][1+1] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44) * idet
    ret[1+1][2+1] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44) * idet
    ret[1+1][3+1] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43) * idet

    ret[2+1][0+1] = t13 * idet
    ret[2+1][1+1] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44) * idet
    ret[2+1][2+1] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44) * idet
    ret[2+1][3+1] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43) * idet

    ret[3+1][0+1] = t14 * idet
    ret[3+1][1+1] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34) * idet
    ret[3+1][2+1] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34) * idet
    ret[3+1][3+1] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33) * idet

    return ret
)

clearListener()
print "mine"
print (inverseTest $.transform)


print "max"
(inverse $.transform)