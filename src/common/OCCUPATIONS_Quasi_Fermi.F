!
!        Copyright (C) 2000-2017 Claudio Attaccalite
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
subroutine OCCUPATIONS_Quasi_Fermi(E,K,mode)
 !
 ! Mode = 0 
 !  Update the Fermi energy
 !  Output : E%E_fermi
 !
 ! Mode = 1 -> Mode 0 +
 !  Define E%f and reports variations in Ef/nbf/nbm
 !  Output : E%nbf,E%nbm
 !  E%E are shifted 
 !
 ! Mode > 1 -> Mode 1 +
 !  Full report of system electronic character
 !
 use pars,          ONLY:SP,DP
 use units,         ONLY:HA2EV
 use electrons,     ONLY:levels,nel_cond,nel,E_duplicate,E_reset
 use R_lattice,     ONLY:bz_samp
 use IO_m,          ONLY:IO_and_Messaging_switch
 use com,           ONLY:error,msg
 use parser_m,      ONLY:parser
 use lum_m,         ONLY:k_vertical_exc
 !
 implicit none
 !
 type(levels) ::E
 type(bz_samp)::K
 integer      ::mode
 !
 ! Work Space
 !
 type(levels) :: E_plus,E_minus
 real(SP) :: nel_save
 integer  :: nbf_save,nbm_save
 integer  :: nval 
 logical  :: l_gamma_exc
 !
 call  OCCUPATIONS_Fermi(E,K,mode)
 !
 if(nel_cond==0._SP) return
 !
 if(k_vertical_exc/=0) then
   call Vertical_Occupation(E,K,mode,k_vertical_exc)
   return
 endif
 !
 nel_save=nel
 !
 call E_reset(E_plus)
 call E_reset(E_minus)
 call E_duplicate(E,E_plus)
 call E_duplicate(E,E_minus)
 !
 if(E%nbf/=E%nbm) call error("Quasi-Fermi distribution only for insulators/semiconductors")
 !
 nval=E%nbf
 nel =nel+nel_cond
 !
 call IO_and_Messaging_switch("-report -log -io_in -io_out")
 call OCCUPATIONS_Fermi(E_plus,K,mode)
 !
 nbm_save=E_plus%nbm
 !
 nel =nel_save
 nel =nel-nel_cond
 !
 call OCCUPATIONS_Fermi(E_minus,K,mode)
 call IO_and_Messaging_switch("+report +log +io_in +io_out")
 !
 nbf_save=E_minus%nbf
 !
 call REPORT_all_Occupations(E_minus,k,'E_minus')
 call REPORT_all_Occupations(E_plus,k,'E_plus')
 !
 call OCCUPATIONS_Merge(E,E_minus,E_plus,K,mode) ! Generate a Quasi-Fermi distribution in E using E_minus and E_plus
 !
 nel  =nel_save
 E%nbf=nbf_save
 E%nbm=nbm_save
 !
 call msg('rsn','Number of metalic bands : ',E%nbm)
 call msg('rsn','Number of filled  bands : ',E%nbf)
 call msg('rsn','Number of valence bands : ',nval)
 !
 call REPORT_all_Occupations(E,k,'E')
 !
 call E_reset(E_plus)
 call E_reset(E_minus)
 !
end subroutine
