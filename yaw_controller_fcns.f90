module yaw_controller_fcns
!use misc_mod
! Types
  integer, parameter :: mk = kind(1.0d0)
  real(mk) pi, degrad, raddeg
   parameter(pi = 3.14159265358979_mk, degrad = 0.01745329251994_mk, raddeg = 57.295779513093144_mk)
type yaw_str

  real*8 :: tstart
  integer :: larray , larray2
  real*8 :: threshold, lastyaw, ct , memory
  real*8 :: flagyaw
  real(mk) :: array4(100000), arrayaux(1,100000)
  
end type yaw_str

type(yaw_str) yawst


!*****************************************************************************************
contains
!*****************************************************************************************
end module yaw_controller_fcns