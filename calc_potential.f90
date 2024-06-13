subroutine calc_potential
    use variables
    use parameters
    implicit none
    integer :: i1, i2, j, kind1, kind2
    double precision :: r, LJ_potential, force
    double precision :: div2, div4, div6, div8, div12, div14
    double precision :: divs(3), for(3)

    ! 初期化
    acc(:, :, :) = 0.0000D0
    pot(:, :) = 0.0000D0

    do kind1 = 1, 3
        do kind2 = kind1, 3
            if (kind1 == U_PT .and. kind2 == L_PT) cycle ! 上部Ptと下部Ptの計算をスキップ
            do i1 = 1, N(kind1)
                LP: do i2 = 1, N(kind2)
                        !! 同じ粒子
                        if ((kind1 == kind2) .and. (i1 == i2)) cycle LP

                        ! 相対位置ベクトル
                        divs(:) = pos(kind1, i1, :) - pos(kind2, i2, :)

                        ! 相対位置ベクトルが零ベクトルになる場合
                        if (divs(1) == 0.0D0 .and. divs(2) == 0.0D0 .and. divs(3) == 0.0D0) then
                            write(6,*) "! divs(:) = 0.0 !"
                            write(6,*) "kind1, kind2: ", kind1, kind2
                            write(6,*) "i1, i2: ", i1, i2
                            write(6,*) "Program will stop."
                            stop
                        endif

                        ! xy周期境界条件の適用
                        do j = 1, 2
                            if (divs(j) < -CUTOFF(kind1, kind2, j)) then
                                divs(j) = divs(j) + ssize(j)
                            else if (divs(j) > CUTOFF(kind1, kind2, j)) then
                                divs(j) = divs(j) - ssize(j)
                            endif
                        end do

                        ! カットオフ
                        do j = 1, 3
                            divs(j) = divs(j) / SIG(kind1, kind2)
                            if (abs(divs(j)) > CUTOFFperSIG) cycle LP
                        end do

                        div2 = divs(1)*divs(1) + divs(2)*divs(2) + divs(3)*divs(3)
                        r = dsqrt(div2)

                        ! カットオフ
                        if (r > CUTOFFperSIG) cycle LP

                        div4 = div2*div2
                        div6 = div4*div2
                        div8 = div4*div4
                        div12 = div6*div6
                        div14 = div8*div6

                        LJ_potential = 4.00D0*EPS(kind1, kind2)*(1.00D0/div12 - 1.00D0/div6)
                        force = COEF(kind1, kind2)*(-2.00D0/div14 + 1.00D0/div8)
                        for(:) = -force * divs(:)

                        acc(kind1, i1, :) = acc(kind1, i1, :) + for(:) / MASS(kind1)
                        acc(kind2, i2, :) = acc(kind2, i2, :) - for(:) / MASS(kind2)

                        pot(kind1, i1) = pot(kind1, i1) + LJ_potential*0.500D0
                        pot(kind2, i2) = pot(kind2, i2) + LJ_potential*0.500D0
                    end do LP
            end do
        end do
    end do
end subroutine calc_potential
