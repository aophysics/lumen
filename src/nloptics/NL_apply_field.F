!
!        Copyright (C) 2000-2016 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): AM CA DS
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
subroutine NL_apply_field(ik,H_nl_sc,A_input)
 !
 ! This subroutine add the vector potential to the Hamiltonian
 !
 use pars,           ONLY:SP,cI
 use electrons,      ONLY:n_sp_pol
 use units,          ONLY:SPEED_OF_LIGHT
 use fields,         ONLY:gauge_field
 use X_m,            ONLY:DIP_iR,DIP_P,global_gauge
 use nl_optics,      ONLY:NL_bands
 use parallel_m,     ONLY:PAR_Xk_ibz_index
 !
 implicit none
 integer,           intent(in) :: ik
 complex(SP),    intent(inout) :: H_nl_sc(NL_bands(2),NL_bands(2),n_sp_pol)
 type(gauge_field), intent(in) :: A_input
 ! 
 ! Work Space
 !
 integer     :: i1,i2
 complex(SP) :: A_dot_J,E_dot_P,A_vec_pot(3),E_vec_pot(3),POL(3),CURR(3)
 !
 if(trim(global_gauge)=='velocity') then
   !
   ! Velocity gauge
   !================
   !
   A_vec_pot=A_input%vecpot/SPEED_OF_LIGHT ! Gaussian units
   !
   ! Add the vector potential to the singular part of the Self-Energy
   ! in case of complex Efield puts the correct Hermitian matrix
   ! and the intraband optical matrix elements have been set to zero
   !
!$omp parallel do default(shared), private(i1,CURR,A_dot_J)
   do i1=NL_bands(1),NL_bands(2)
     CURR(1:3)= -DIP_P(1:3,i1,i1,PAR_Xk_ibz_index(ik),1)+A_vec_pot(1:3)/2._SP
     A_dot_J=sum(A_vec_pot(1:3)*CURR(1:3)) 
     H_nl_sc(i1,i1,1)=H_nl_sc(i1,i1,1)-real(A_dot_J,SP)
   enddo
!$omp end parallel do
   !
!$omp parallel do default(shared), private(i1,i2,CURR,A_dot_J)
   do i1=NL_bands(1),NL_bands(2)
     do i2=i1+1,NL_bands(2)
       !
       ! Note that (P)_cv = DIP_P (:,iv,ic,:,:)
       !     
       CURR(:)=-DIP_P(1:3,i1,i2,PAR_Xk_ibz_index(ik),1) ! the off-diagonal diamagnetic term is zero
       A_dot_J=sum(A_vec_pot(1:3)*CURR(1:3)) 
       H_nl_sc(i1,i2,1)=H_nl_sc(i1,i2,1)-      A_dot_J
       H_nl_sc(i2,i1,1)=H_nl_sc(i2,i1,1)-conjg(A_dot_J)
       !
     enddo
   enddo
!$omp end parallel do
   !
   ! Correction to the pseudo should be included here ... <nk|V(r,r')[exp(iA*(r-r'))-1]|n'k>
   !
 else  
   !
   ! Length gauge
   !===============
   !
   E_vec_pot=-A_input%vecpot_vel/SPEED_OF_LIGHT ! Gaussian units
   !
   ! Intraband terms
   !
!$omp parallel do default(shared), private(i1,POL,E_dot_P)
   do i1=NL_bands(1),NL_bands(2)
     POL(:)=cI*DIP_iR(:,i1,i1,PAR_Xk_ibz_index(ik),1)
     E_dot_P=sum(E_vec_pot(1:3)*POL(1:3))
     H_nl_sc(i1,i1,1)=H_nl_sc(i1,i1,1)-real(E_dot_P,SP)
   enddo
!$omp end parallel do
   !
!$omp parallel do default(shared), private(i1,i2,POL,E_dot_P)
   do i1=NL_bands(1),NL_bands(2)
     do i2=i1+1,NL_bands(2)
       !
       ! Note that (iR)_cv = DIP_iR (:,iv,ic,:,:)
       !
       POL(:)=cI*DIP_iR(:,i2,i1,PAR_Xk_ibz_index(ik),1)
       E_dot_P=sum(E_vec_pot(1:3)*POL(1:3))
       H_nl_sc(i1,i2,1)=H_nl_sc(i1,i2,1)-      E_dot_P
       H_nl_sc(i2,i1,1)=H_nl_sc(i2,i1,1)-conjg(E_dot_P)
       !
     enddo
   enddo
!$omp end parallel do
 endif
 !
end subroutine NL_apply_field
