!
!        Copyright (C) 2000-2016 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): CA
! 
! This file is distributed under the terms of the GNU 
! General Public License. You can redistribute it and/or 
! modify it under the terms of the GNU General Public 
! License as published by the Free Software Foundation; 
! either version 2, or (at your option) any later version.
!
! This program is distributed in the hope that it will 
! be useful, but WITHOUT ANY WARRANTY; without even the 
! implied warranty of MERCHANTABILITY or FITNESS FOR A 
! PARTICULAR PURPOSE.  See the GNU General Public License 
! for more details.
!
! You should have received a copy of the GNU General Public 
! License along with this program; if not, write to the Free 
! Software Foundation, Inc., 59 Temple Place - Suite 330,Boston, 
! MA 02111-1307, USA or visit http://www.gnu.org/copyleft/gpl.txt.
!
subroutine fourier_interpolation(USER_k,VALUES,engre,nvalues,Nk)
  !
  use pars,           ONLY:SP,pi,cI,cZERO,DP
  use interpolate,    ONLY:nshells,lattice_vectors,make_star,metric,int_sop
  use R_lattice,      ONLY:bz_samp
  use D_lattice,      ONLY:nsym
  use vec_operate,    ONLY:c2a
  use memory_m,       ONLY:mem_est
  implicit none
  !
  integer,intent(in)        :: nvalues
  integer,intent(in)        :: Nk
  type(bz_samp), intent(in) :: USER_k
  real(SP), intent(out)     :: VALUES(nvalues,Nk)
  real(SP), parameter       :: twopi=2._SP*pi
  complex(DP), intent(in)   :: engre(nshells,nvalues)
  !
  ! Work Space
  !
  integer  :: i1,iv,ik,is,nstar
  real(SP) :: star_vec(3,nsym),v(3)
  complex(SP), allocatable :: star(:,:)
  !
  allocate (star(nshells,Nk))
  call mem_est("star",(/size(star)/),(/SP/))
  !
  ! Make stars
  !
  star=cZERO
  do i1=1,nshells
     call make_star(lattice_vectors(:,i1),nsym,int_sop,nstar,star_vec)  
     do ik=1,Nk
       if(Nk==USER_k%nibz) call c2a(v_in=USER_k%pt(ik,:),v_out=v,mode='ki2a')
       do is=1,nstar
         star(i1,ik)=star(i1,ik) + exp(cI*twopi*dot_product(v(:),star_vec(:,is)))
       enddo
       star(i1,ik)=star(i1,ik)/real(nstar)
    enddo
  enddo
  !
  do ik=1,Nk
    do iv=1,nvalues
      VALUES(iv,ik) = sum(engre(1:nshells,iv)*star(1:nshells,ik))
    enddo
  enddo
  !
  deallocate (star)
  call mem_est("star")
  !
end subroutine fourier_interpolation
