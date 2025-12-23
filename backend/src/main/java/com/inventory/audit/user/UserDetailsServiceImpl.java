package com.inventory.audit.user;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.stream.Collectors;

/**
 * Implementation of Spring Security's UserDetailsService.
 * Loads user details for authentication.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the implementation of the UserDetailsService. */
@Service
public class UserDetailsServiceImpl implements UserDetailsService 
{
    
    @Autowired
    private UserRepository userRepository;
    
    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException 
    {
        com.inventory.audit.user.User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
        
        if (!user.getEnabled()){throw new UsernameNotFoundException("User account is disabled: " + username);}
        
        return User.builder()
                .username(user.getUsername())
                .password(user.getPasswordHash())
                .authorities(getAuthorities(user))
                .accountExpired(false)
                .accountLocked(false)
                .credentialsExpired(false)
                .disabled(!user.getEnabled())
                .build();
    }
    
    /* This method returns the authorities for the user. */
    private Collection<? extends GrantedAuthority> getAuthorities(com.inventory.audit.user.User user) 
    {
        return user.getRoles().stream().map(role -> new SimpleGrantedAuthority("ROLE_" + role.getName())).collect(Collectors.toList());
    }
}

