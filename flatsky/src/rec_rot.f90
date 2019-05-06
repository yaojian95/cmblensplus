!///////////////////////////////////////////////////////////!
! Rotation Reconstruction Kernel
!///////////////////////////////////////////////////////////!

module rec_rot
  use constants, only: iu, pi, twopi
  use grid2d,    only: elarrays_2d, make_lmask
  use fftw,      only: dft
  implicit none

  private iu, pi, twopi
  private elarrays_2d, make_lmask
  private dft

contains 


subroutine qte(nx,ny,D,rL,fC,T,E,alm)
!*  Reconstructing anisotropic pol. rot. angles from TE quadratic estimator
  implicit none
  !I/O
  integer, intent(in) :: nx, ny
  integer, intent(in), dimension(2) :: rL
  double precision, intent(in), dimension(2) :: D
  double precision, intent(in), dimension(nx,ny) :: fC
  double complex, intent(in), dimension(nx,ny) :: T, E
  double complex, intent(out), dimension(nx,ny) :: alm
  !internal
  integer :: nn(2)
  double precision, dimension(nx,ny) :: els, lmask
  double complex, dimension(nx,ny) :: aT, aE, ei2p, xlm

  nn = (/nx,ny/)
  call elarrays_2d(nn,D,els=els,ei2p=ei2p)

  ! filtering
  call make_lmask(nn,D,rL,lmask)
  aT = lmask*fC*T*ei2p
  aE = lmask*E*conjg(ei2p)

  ! convolution
  call dft(aE,nn,D,-1)
  call dft(aT,nn,D,-1)
  xlm = -2d0*aimag(aE*aT)
  call dft(xlm,nn,D,1)

  alm = xlm

end subroutine qte


subroutine qtb(nx,ny,D,rL,fC,T,B,alm)
!*  Reconstructing anisotropic pol. rot. angles from TB quadratic estimator
  implicit none
  !I/O
  integer, intent(in) :: nx, ny
  integer, intent(in), dimension(2) :: rL
  double precision, intent(in), dimension(2) :: D
  double precision, intent(in), dimension(nx,ny) :: fC
  double complex, intent(in), dimension(nx,ny) :: T, B
  double complex, intent(out), dimension(nx,ny) :: alm
  !internal
  integer :: nn(2)
  double precision, dimension(nx,ny) :: els, lmask
  double complex, dimension(nx,ny) :: wB, wT, xlm, ei2p

  nn = (/nx,ny/)
  call elarrays_2d(nn,D,els=els,ei2p=ei2p)

  ! filtering
  call make_lmask(nn,D,rL,lmask)
  wT = lmask*fC*T*ei2p
  wB = lmask*B*conjg(ei2p)

  ! convolution
  call dft(wB,nn,D,-1)
  call dft(wT,nn,D,-1)
  xlm = 2d0*dble(wB*wT)
  call dft(xlm,nn,D,1)

  alm = xlm

end subroutine qtb


subroutine qee(nx,ny,D,rL,fC,E1,E2,alm)
!*  Reconstructing anisotropic pol. rot. angles from EE quadratic estimator
  implicit none
  !I/O
  integer, intent(in) :: nx, ny
  integer, intent(in), dimension(2) :: rL
  double precision, intent(in), dimension(2) :: D
  double precision, intent(in), dimension(nx,ny) :: fC
  double complex, intent(in), dimension(nx,ny) :: E1, E2
  double complex, intent(out), dimension(nx,ny) :: alm
  !internal
  integer :: nn(2)
  double precision, dimension(nx,ny) :: els, lmask
  double complex, dimension(nx,ny) :: wE1, wE2, xlm, ei2p

  nn = (/nx,ny/)
  call elarrays_2d(nn,D,els=els,ei2p=ei2p)

  ! filtering
  call make_lmask(nn,D,rL,lmask)
  wE1 = lmask*E1*conjg(ei2p)
  wE2 = lmask*fC*E2*ei2p

  ! convolution
  call dft(wE1,nn,D,-1)
  call dft(wE2,nn,D,-1)
  xlm = -2d0*aimag(wE1*wE2)
  call dft(xlm,nn,D,1)

  alm = xlm

end subroutine qee


subroutine qeb(nx,ny,D,rL,EE,E,B,alm,BB)
!*  Reconstructing anisotropic pol. rot. angles from EB quadratic estimator
  implicit none
  !I/O
  integer, intent(in) :: nx, ny
  integer, intent(in), dimension(2) :: rL
  double precision, intent(in), dimension(2) :: D
  double precision, intent(in), dimension(nx,ny) :: EE
  double complex, intent(in), dimension(nx,ny) :: E, B
  double complex, intent(out), dimension(nx,ny) :: alm
  !(optional)
  double precision, intent(in), optional, dimension(nx,ny) :: BB
  !internal
  integer :: nn(2)
  double precision, dimension(nx,ny) :: lmask, els
  double complex, dimension(nx,ny) :: wE, wB, alm1, alm2, ei2p

  nn = (/nx,ny/)
  call elarrays_2d(nn,D,els=els,ei2p=ei2p)

  !filtering
  call make_lmask(nn,D,rL,lmask)
  wE = lmask*EE*E*ei2p
  wB = lmask*B*conjg(ei2p)

  !convolution
  call dft(wE,nn,D,-1)
  call dft(wB,nn,D,-1)
  alm1 = 2d0*dble(wE*wB)
  call dft(alm1,nn,D,1)

  if (present(BB).and.sum(abs(BB))/=0d0) then
    !filtering
    wE = lmask*E*ei2p
    wB = lmask*BB*B*conjg(ei2p)
    !convolution
    call dft(wE,nn,D,-1)
    call dft(wB,nn,D,-1)
    alm2 = 2d0*dble(wE*wB)
    call dft(alm2,nn,D,1)
  end if

  !estimator
  alm = alm1 + alm2

end subroutine qeb


end module rec_rot


