package com.inventory.audit.user;

import jakarta.persistence.*;
import java.util.Set;

/**
 * Represents a role in the system.
 * Roles define what actions a user can perform.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Entity
@Table(name = "roles")
public class Role {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true, length = 50)
    private String name;
    
    @ManyToMany(mappedBy = "roles")
    private Set<User> users;
    
    /* This constructor is the default constructor. */
    public Role() {}
    
    /* This constructor is the constructor for the Role. */
    public Role(String name) {this.name = name;}
    
    /* These methods are the getters and setters for the Role. */
    public Long getId() {return id;}
    
    public void setId(Long id) {this.id = id;}
    
    public String getName() {return name;}
    
    public void setName(String name) {this.name = name;}
    
    public Set<User> getUsers() {return users;}
    
    public void setUsers(Set<User> users) {this.users = users;}
}

